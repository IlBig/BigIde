// BigIDE Video Viewer — NSPanel overlay sopra fullscreen
// Compilare: swiftc -O bigide-vidview.swift -o bigide-vidview -framework AVKit -framework AVFoundation
// ←/→ scorre solo video | ↑/↓ scorre tutti i file (attraversa cartelle)

import Cocoa
import AVKit
import AVFoundation

class VideoPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class VideoViewController: NSObject {
    let panel: VideoPanel
    let playerView: AVPlayerView
    let player: AVPlayer
    let label: NSTextField
    let counterLabel: NSTextField

    // Lista piatta di TUTTI i file nell'albero (depth-first, attraversa cartelle)
    var allFiles: [String] = []
    var allIndex: Int = 0

    // Solo video (sottoinsieme di allFiles)
    var videoFiles: [String] = []
    var videoIndex: Int = 0

    // Directory radice per path relativi
    var rootDir: String = ""

    private static let videoExtensions: Set<String> = [
        "mp4", "mov", "avi", "mkv", "webm", "m4v",
        "wmv", "flv", "mpg", "mpeg", "3gp", "ts",
    ]

    /// Cartelle da ignorare nella scansione ricorsiva
    private static let skippedDirs: Set<String> = [
        "node_modules", "__pycache__", ".git", ".svn", ".hg",
        "build", "dist", ".next", ".nuxt", "target",
        ".cache", ".tmp", "vendor", "Pods", ".build",
    ]

    static func isVideo(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return videoExtensions.contains(ext)
    }

    init(videoPath: String) {
        guard let screen = NSScreen.main else {
            fputs("Errore: nessun display trovato\n", stderr)
            exit(1)
        }

        let frame = screen.frame

        // Panel flottante — fullScreenAuxiliary per overlay sopra app fullscreen
        panel = VideoPanel(
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

        // Player — centrato con padding
        let padding: CGFloat = 40.0
        let bottomBarHeight: CGFloat = 30.0
        let playerFrame = NSRect(
            x: padding,
            y: padding + bottomBarHeight,
            width: frame.width - padding * 2,
            height: frame.height - padding * 2 - bottomBarHeight
        )

        let url = URL(fileURLWithPath: videoPath)
        player = AVPlayer(url: url)

        playerView = AVPlayerView(frame: playerFrame)
        playerView.player = player
        playerView.controlsStyle = .inline
        playerView.autoresizingMask = [.width, .height]

        // Path relativo in basso (centro)
        let labelFrame = NSRect(
            x: padding,
            y: padding,
            width: frame.width - padding * 2 - 130,
            height: bottomBarHeight
        )
        label = NSTextField(frame: labelFrame)
        label.stringValue = (videoPath as NSString).lastPathComponent
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

        panel.contentView?.addSubview(playerView)
        panel.contentView?.addSubview(label)
        panel.contentView?.addSubview(counterLabel)

        buildFileTree(for: videoPath)
        writeCurrentPath()
        player.play()
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
        videoFiles = allFiles.filter { VideoViewController.isVideo($0) }
        videoIndex = videoFiles.firstIndex(of: path) ?? 0

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
            if !VideoViewController.skippedDirs.contains(d.name) {
                walkDirectory(d.path, maxDepth: maxDepth - 1)
            }
        }

        // Poi aggiungi i file (ordinati)
        for f in files {
            allFiles.append(f.path)
        }
    }

    // MARK: - Navigazione

    /// ←/→ — naviga solo video (attraversa cartelle)
    func navigateVideos(delta: Int) {
        guard videoFiles.count > 1 else { return }
        videoIndex = (videoIndex + delta + videoFiles.count) % videoFiles.count
        let newPath = videoFiles[videoIndex]
        showVideo(at: newPath)
        if let idx = allFiles.firstIndex(of: newPath) { allIndex = idx }
    }

    /// ↑/↓ — naviga tutti i file. Stesso tipo: fluido interno. Altro tipo: delega neo-tree
    func navigateAll(delta: Int) -> Bool {
        guard allFiles.count > 1 else { return true }
        let newIndex = (allIndex + delta + allFiles.count) % allFiles.count
        let newPath = allFiles[newIndex]

        if VideoViewController.isVideo(newPath) {
            allIndex = newIndex
            showVideo(at: newPath)
            if let idx = videoFiles.firstIndex(of: newPath) { videoIndex = idx }
            return true
        } else {
            // Cambio tipo: direzione + path fallback per neo-tree
            let direction = delta > 0 ? "down" : "up"
            try? "\(direction)\n\(newPath)".write(toFile: "/tmp/bigide-vidview-next", atomically: true, encoding: .utf8)
            return false
        }
    }

    private func showVideo(at path: String) {
        player.pause()
        let url = URL(fileURLWithPath: path)
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.play()
        updateLabels()
        writeCurrentPath()
    }

    private func writeCurrentPath() {
        guard !allFiles.isEmpty, allIndex < allFiles.count else { return }
        try? allFiles[allIndex].write(toFile: "/tmp/bigide-viewer-current", atomically: true, encoding: .utf8)
    }

    private func updateLabels() {
        guard !allFiles.isEmpty, allIndex < allFiles.count else { return }
        let path = allFiles[allIndex]

        // Mostra path relativo dalla root (es. "subdir/video.mp4")
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
    var viewController: VideoViewController!
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        guard args.count > 1 else {
            fputs("Uso: bigide-vidview <percorso-video>\n", stderr)
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

        viewController = VideoViewController(videoPath: resolvedPath)
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
                    self?.viewController.player.pause()
                    self?.writeLastFile()
                    NSApp.terminate(nil)
                    return nil
                }

                // ← freccia sinistra → video precedente
                if keyCode == 123 {
                    self?.viewController.navigateVideos(delta: -1)
                    return nil
                }

                // → freccia destra → video successivo
                if keyCode == 124 {
                    self?.viewController.navigateVideos(delta: 1)
                    return nil
                }

                // ↑ freccia su → file precedente (tutti i tipi, attraversa cartelle)
                if keyCode == 126 {
                    if !(self?.viewController.navigateAll(delta: -1) ?? true) {
                        self?.viewController.player.pause()
                        NSApp.terminate(nil)
                    }
                    return nil
                }

                // ↓ freccia giù → file successivo (tutti i tipi, attraversa cartelle)
                if keyCode == 125 {
                    if !(self?.viewController.navigateAll(delta: 1) ?? true) {
                        self?.viewController.player.pause()
                        NSApp.terminate(nil)
                    }
                    return nil
                }
            } else if event.type == .leftMouseDown {
                guard self?.viewController.panel.contentView != nil else { return event }
                let loc = event.locationInWindow
                let playerFrame = self?.viewController.playerView.frame ?? .zero
                if !playerFrame.contains(loc) {
                    self?.viewController.player.pause()
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
            try? path.write(toFile: "/tmp/bigide-vidview-last", atomically: true, encoding: .utf8)
        }
    }
}

// --- Main ---
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
