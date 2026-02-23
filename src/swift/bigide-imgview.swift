// BigIDE Image Viewer — NSPanel overlay sopra fullscreen
// Compilare: swiftc -O bigide-imgview.swift -o bigide-imgview
// ←/→ scorre solo immagini | ↑/↓ scorre tutti i file (attraversa cartelle)

import Cocoa

class ImagePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class ImageViewController: NSObject {
    let panel: ImagePanel
    let imageView: NSImageView
    let label: NSTextField
    let counterLabel: NSTextField

    // Lista piatta di TUTTI i file nell'albero (depth-first, attraversa cartelle)
    var allFiles: [String] = []
    var allIndex: Int = 0

    // Solo immagini (sottoinsieme di allFiles)
    var imageFiles: [String] = []
    var imageIndex: Int = 0

    // Directory radice per path relativi
    var rootDir: String = ""

    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "webp", "bmp",
        "tiff", "tif", "ico", "heic", "heif", "svg",
        "avif", "jxl", "qoi",
    ]

    /// Cartelle da ignorare nella scansione ricorsiva
    private static let skippedDirs: Set<String> = [
        "node_modules", "__pycache__", ".git", ".svn", ".hg",
        "build", "dist", ".next", ".nuxt", "target",
        ".cache", ".tmp", "vendor", "Pods", ".build",
    ]

    static func isImage(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return imageExtensions.contains(ext)
    }

    init(imagePath: String) {
        guard let screen = NSScreen.main else {
            fputs("Errore: nessun display trovato\n", stderr)
            exit(1)
        }
        guard let image = NSImage(contentsOfFile: imagePath) else {
            fputs("Errore: impossibile caricare \(imagePath)\n", stderr)
            exit(1)
        }

        let frame = screen.frame

        // Panel flottante — fullScreenAuxiliary per overlay sopra app fullscreen
        panel = ImagePanel(
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

        // Immagine — aspect-fit centrata
        let padding: CGFloat = 40.0
        let bottomBarHeight: CGFloat = 30.0
        let imageFrame = NSRect(
            x: padding,
            y: padding + bottomBarHeight,
            width: frame.width - padding * 2,
            height: frame.height - padding * 2 - bottomBarHeight
        )
        imageView = NSImageView(frame: imageFrame)
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.autoresizingMask = [.width, .height]

        // Path relativo in basso (centro)
        let labelFrame = NSRect(
            x: padding,
            y: padding,
            width: frame.width - padding * 2 - 130,
            height: bottomBarHeight
        )
        label = NSTextField(frame: labelFrame)
        label.stringValue = (imagePath as NSString).lastPathComponent
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

        panel.contentView?.addSubview(imageView)
        panel.contentView?.addSubview(label)
        panel.contentView?.addSubview(counterLabel)

        buildFileTree(for: imagePath)
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
        imageFiles = allFiles.filter { ImageViewController.isImage($0) }
        imageIndex = imageFiles.firstIndex(of: path) ?? 0

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
            if !ImageViewController.skippedDirs.contains(d.name) {
                walkDirectory(d.path, maxDepth: maxDepth - 1)
            }
        }

        // Poi aggiungi i file (ordinati)
        for f in files {
            allFiles.append(f.path)
        }
    }

    // MARK: - Navigazione

    /// ←/→ — naviga solo immagini (attraversa cartelle)
    func navigateImages(delta: Int) {
        guard imageFiles.count > 1 else { return }
        imageIndex = (imageIndex + delta + imageFiles.count) % imageFiles.count
        let newPath = imageFiles[imageIndex]
        showImage(at: newPath)
        if let idx = allFiles.firstIndex(of: newPath) { allIndex = idx }
    }

    /// ↑/↓ — naviga tutti i file. Ritorna false se transizione a non-immagine
    func navigateAll(delta: Int) -> Bool {
        guard allFiles.count > 1 else { return true }
        let newIndex = (allIndex + delta + allFiles.count) % allFiles.count
        let newPath = allFiles[newIndex]

        if ImageViewController.isImage(newPath) {
            allIndex = newIndex
            showImage(at: newPath)
            if let idx = imageFiles.firstIndex(of: newPath) { imageIndex = idx }
            return true
        } else {
            // Transizione a file non-immagine
            try? newPath.write(toFile: "/tmp/bigide-imgview-next", atomically: true, encoding: .utf8)
            return false
        }
    }

    private func showImage(at path: String) {
        guard let newImage = NSImage(contentsOfFile: path) else { return }
        imageView.image = newImage
        updateLabels()
    }

    private func updateLabels() {
        guard !allFiles.isEmpty, allIndex < allFiles.count else { return }
        let path = allFiles[allIndex]

        // Mostra path relativo dalla root (es. "subdir/photo.jpg")
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
    var viewController: ImageViewController!
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        guard args.count > 1 else {
            fputs("Uso: bigide-imgview <percorso-immagine>\n", stderr)
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

        viewController = ImageViewController(imagePath: resolvedPath)
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

                // ← freccia sinistra → immagine precedente
                if keyCode == 123 {
                    self?.viewController.navigateImages(delta: -1)
                    return nil
                }

                // → freccia destra → immagine successiva
                if keyCode == 124 {
                    self?.viewController.navigateImages(delta: 1)
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
                let imgFrame = self?.viewController.imageView.frame ?? .zero
                if !imgFrame.contains(loc) {
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
            try? path.write(toFile: "/tmp/bigide-imgview-last", atomically: true, encoding: .utf8)
        }
    }
}

// --- Main ---
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
