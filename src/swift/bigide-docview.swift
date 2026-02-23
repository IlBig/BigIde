// BigIDE Document Viewer — NSPanel overlay con QLPreviewView sopra fullscreen
// Compilare: swiftc -O bigide-docview.swift -o bigide-docview -framework Quartz
// ←/→ scorre solo documenti | ↑/↓ scorre tutti i file (attraversa cartelle)

import Cocoa
import Quartz
import PDFKit

class DocPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - QLPreviewItem wrapper

class DocPreviewItem: NSObject, QLPreviewItem {
    let fileURL: URL
    init(url: URL) { self.fileURL = url; super.init() }
    var previewItemURL: URL! { fileURL }
    var previewItemTitle: String! { fileURL.lastPathComponent }
}

class DocViewController: NSObject {
    let panel: DocPanel
    let previewView: QLPreviewView
    let label: NSTextField
    let counterLabel: NSTextField

    // Lista piatta di TUTTI i file nell'albero (depth-first, attraversa cartelle)
    var allFiles: [String] = []
    var allIndex: Int = 0

    // Solo documenti (sottoinsieme di allFiles)
    var docFiles: [String] = []
    var docIndex: Int = 0

    // Directory radice per path relativi
    var rootDir: String = ""

    private static let docExtensions: Set<String> = [
        "pdf", "docx", "xlsx", "pptx", "doc", "xls", "ppt",
        "pages", "numbers", "key", "odt", "ods", "odp",
    ]

    /// Cartelle da ignorare nella scansione ricorsiva
    private static let skippedDirs: Set<String> = [
        "node_modules", "__pycache__", ".git", ".svn", ".hg",
        "build", "dist", ".next", ".nuxt", "target",
        ".cache", ".tmp", "vendor", "Pods", ".build",
    ]

    static func isDocument(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return docExtensions.contains(ext)
    }

    init(docPath: String) {
        guard let screen = NSScreen.main else {
            fputs("Errore: nessun display trovato\n", stderr)
            exit(1)
        }

        let frame = screen.frame

        // Panel flottante — fullScreenAuxiliary per overlay sopra app fullscreen
        panel = DocPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        panel.isOpaque = false
        panel.hasShadow = false
        panel.backgroundColor = NSColor(white: 0.05, alpha: 0.45)
        panel.isMovableByWindowBackground = false

        // QLPreviewView — centrata con padding
        let padding: CGFloat = 40.0
        let bottomBarHeight: CGFloat = 30.0
        let previewFrame = NSRect(
            x: padding,
            y: padding + bottomBarHeight,
            width: frame.width - padding * 2,
            height: frame.height - padding * 2 - bottomBarHeight
        )
        previewView = QLPreviewView(frame: previewFrame, style: .normal)!
        previewView.autoresizingMask = [.width, .height]
        previewView.autostarts = true

        // Path relativo in basso (centro)
        let labelFrame = NSRect(
            x: padding,
            y: padding,
            width: frame.width - padding * 2 - 130,
            height: bottomBarHeight
        )
        label = NSTextField(frame: labelFrame)
        label.stringValue = (docPath as NSString).lastPathComponent
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.textColor = NSColor(white: 0.7, alpha: 1.0)
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.alignment = .center
        label.autoresizingMask = [.width]

        // Contatore in basso a destra
        let counterFrame = NSRect(
            x: frame.width - padding - 120,
            y: padding,
            width: 120,
            height: bottomBarHeight
        )
        counterLabel = NSTextField(frame: counterFrame)
        counterLabel.isEditable = false
        counterLabel.isBordered = false
        counterLabel.drawsBackground = false
        counterLabel.textColor = NSColor(white: 0.5, alpha: 1.0)
        counterLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        counterLabel.alignment = .right
        counterLabel.autoresizingMask = [.minXMargin]

        super.init()

        panel.contentView?.addSubview(previewView)
        panel.contentView?.addSubview(label)
        panel.contentView?.addSubview(counterLabel)

        // Carica il documento iniziale
        showDocument(at: docPath)
        buildFileTree(for: docPath)
    }

    // MARK: - Scansione ricorsiva albero (depth-first)

    private func buildFileTree(for path: String) {
        let fileDir = (path as NSString).deletingLastPathComponent

        // Leggi nav-root (preservato tra transizioni) o usa la dir del file
        if let rootContent = try? String(contentsOfFile: "/tmp/bigide-nav-root", encoding: .utf8) {
            let trimmed = rootContent.trimmingCharacters(in: .whitespacesAndNewlines)
            rootDir = trimmed.isEmpty ? fileDir : trimmed
        } else {
            rootDir = fileDir
        }

        allFiles = []
        walkDirectory(rootDir, maxDepth: 8)

        allIndex = allFiles.firstIndex(of: path) ?? 0
        docFiles = allFiles.filter { DocViewController.isDocument($0) }
        docIndex = docFiles.firstIndex(of: path) ?? 0

        updateLabels()
    }

    /// Scansione ricorsiva depth-first — cartelle PRIMA dei file (come neo-tree)
    private func walkDirectory(_ dir: String, maxDepth: Int) {
        guard maxDepth > 0, allFiles.count < 5000 else { return }
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(atPath: dir) else { return }

        // Classifica e ordina: cartelle prima, poi file (come neo-tree)
        var dirs: [(name: String, path: String)] = []
        var files: [(name: String, path: String)] = []

        for name in items where !name.hasPrefix(".") {
            let path = (dir as NSString).appendingPathComponent(name)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                dirs.append((name, path))
            } else {
                files.append((name, path))
            }
        }

        dirs.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        files.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        // Prima ricorri nelle cartelle (ordinate)
        for d in dirs {
            if !DocViewController.skippedDirs.contains(d.name) {
                walkDirectory(d.path, maxDepth: maxDepth - 1)
            }
        }

        // Poi aggiungi i file (ordinati)
        for f in files {
            allFiles.append(f.path)
        }
    }

    // MARK: - Navigazione

    /// ←/→ — naviga solo documenti (attraversa cartelle)
    func navigateDocuments(delta: Int) {
        guard docFiles.count > 1 else { return }
        docIndex = (docIndex + delta + docFiles.count) % docFiles.count
        let newPath = docFiles[docIndex]
        showDocument(at: newPath)
        if let idx = allFiles.firstIndex(of: newPath) { allIndex = idx }
    }

    /// ↑/↓ — naviga tutti i file. Ritorna false se transizione a non-documento
    func navigateAll(delta: Int) -> Bool {
        guard allFiles.count > 1 else { return true }
        let newIndex = (allIndex + delta + allFiles.count) % allFiles.count
        let newPath = allFiles[newIndex]

        if DocViewController.isDocument(newPath) {
            allIndex = newIndex
            showDocument(at: newPath)
            if let idx = docFiles.firstIndex(of: newPath) { docIndex = idx }
            return true
        } else {
            // Transizione a file non-documento
            try? newPath.write(toFile: "/tmp/bigide-docview-next", atomically: true, encoding: .utf8)
            return false
        }
    }

    private func showDocument(at path: String) {
        let url = URL(fileURLWithPath: path)
        previewView.previewItem = DocPreviewItem(url: url)
        updateLabels()

        // Dopo che QLPreviewView ha caricato il PDF, imposta zoom "fit page"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.applyFitPageZoom()
        }
    }

    /// Cerca ricorsivamente un PDFView nella gerarchia di QLPreviewView e imposta autoScales
    private func applyFitPageZoom() {
        if let pdfView = findPDFView(in: previewView) {
            pdfView.autoScales = true
            pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        }
    }

    private func findPDFView(in view: NSView) -> PDFView? {
        if let pdfView = view as? PDFView {
            return pdfView
        }
        for subview in view.subviews {
            if let found = findPDFView(in: subview) {
                return found
            }
        }
        return nil
    }

    private func updateLabels() {
        guard !allFiles.isEmpty, allIndex < allFiles.count else { return }
        let path = allFiles[allIndex]

        // Mostra path relativo dalla root (es. "subdir/report.pdf")
        if path.hasPrefix(rootDir + "/") {
            label.stringValue = String(path.dropFirst(rootDir.count + 1))
        } else {
            label.stringValue = (path as NSString).lastPathComponent
        }
        counterLabel.stringValue = "\(allIndex + 1) / \(allFiles.count)"
    }

    func currentPath() -> String {
        guard !allFiles.isEmpty, allIndex < allFiles.count else { return "" }
        return allFiles[allIndex]
    }

    func show() {
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var viewController: DocViewController!
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        guard args.count > 1 else {
            fputs("Uso: bigide-docview <percorso-documento>\n", stderr)
            NSApp.terminate(nil)
            return
        }

        let path = args[1]
        guard FileManager.default.fileExists(atPath: path) else {
            fputs("File non trovato: \(path)\n", stderr)
            NSApp.terminate(nil)
            return
        }

        // Risolvi percorso relativo
        let resolvedPath: String
        if path.hasPrefix("/") {
            resolvedPath = path
        } else {
            resolvedPath = FileManager.default.currentDirectoryPath + "/" + path
        }

        viewController = DocViewController(docPath: resolvedPath)
        viewController.show()

        // Monitor tastiera e mouse
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown]
        ) { [weak self] event in
            if event.type == .keyDown {
                let key = event.charactersIgnoringModifiers ?? ""
                let keyCode = event.keyCode

                // Esc, q, Spazio → chiudi
                if keyCode == 53 || key == "q" || key == " " {
                    self?.writeLastFile()
                    NSApp.terminate(nil)
                    return nil
                }

                // ← freccia sinistra → documento precedente
                if keyCode == 123 {
                    self?.viewController.navigateDocuments(delta: -1)
                    return nil
                }

                // → freccia destra → documento successivo
                if keyCode == 124 {
                    self?.viewController.navigateDocuments(delta: 1)
                    return nil
                }

                // ↑ freccia su → file precedente (tutti i tipi, attraversa cartelle)
                if keyCode == 126 {
                    if !(self?.viewController.navigateAll(delta: -1) ?? true) {
                        NSApp.terminate(nil)
                    }
                    return nil
                }

                // ↓ freccia giù → file successivo (tutti i tipi, attraversa cartelle)
                if keyCode == 125 {
                    if !(self?.viewController.navigateAll(delta: 1) ?? true) {
                        NSApp.terminate(nil)
                    }
                    return nil
                }
            } else if event.type == .leftMouseDown {
                guard self?.viewController.panel.contentView != nil else { return event }
                let loc = event.locationInWindow
                let previewFrame = self?.viewController.previewView.frame ?? .zero
                if !previewFrame.contains(loc) {
                    self?.writeLastFile()
                    NSApp.terminate(nil)
                    return nil
                }
            }
            return event
        }
    }

    private func writeLastFile() {
        let path = viewController.currentPath()
        if !path.isEmpty {
            try? path.write(toFile: "/tmp/bigide-docview-last", atomically: true, encoding: .utf8)
        }
    }
}

// --- Main ---
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
