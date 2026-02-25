// BigIDE Browser — NSPanel overlay con WKWebView sopra fullscreen
// Compilare: swiftc -O bigide-browser.swift -o bigide-browser -framework WebKit
// Uso: bigide-browser [URL]
// Esc/click sfondo → chiudi | Cmd+L → URL bar | Cmd+R → ricarica

import Cocoa
import WebKit

class BrowserPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class BrowserViewController: NSObject, WKNavigationDelegate, NSTextFieldDelegate {
    let panel: BrowserPanel
    let webView: WKWebView
    let urlField: NSTextField
    let statusLabel: NSTextField

    init(urlString: String) {
        guard let screen = NSScreen.main else {
            fputs("Errore: nessun display trovato\n", stderr)
            exit(1)
        }

        let frame = screen.frame
        let padding: CGFloat = 30.0
        let topBarHeight: CGFloat = 32.0
        let bottomBarHeight: CGFloat = 24.0
        let gap: CGFloat = 6.0

        // Panel flottante — fullScreenAuxiliary per overlay sopra app fullscreen
        panel = BrowserPanel(
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

        // URL field al top — barra indirizzi
        let urlFrame = NSRect(
            x: padding,
            y: frame.height - padding - topBarHeight,
            width: frame.width - padding * 2,
            height: topBarHeight
        )
        urlField = NSTextField(frame: urlFrame)
        urlField.stringValue = urlString
        urlField.placeholderString = "Cerca o digita URL"
        urlField.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        urlField.textColor = NSColor(white: 0.9, alpha: 1.0)
        urlField.backgroundColor = NSColor(white: 0.12, alpha: 1.0)
        urlField.isBezeled = true
        urlField.bezelStyle = .roundedBezel
        urlField.focusRingType = .none
        urlField.drawsBackground = true
        urlField.autoresizingMask = [.width]

        // WKWebView al centro
        let webFrame = NSRect(
            x: padding,
            y: padding + bottomBarHeight + gap,
            width: frame.width - padding * 2,
            height: frame.height - padding * 2 - topBarHeight - bottomBarHeight - gap * 2
        )
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView = WKWebView(frame: webFrame, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.wantsLayer = true
        webView.layer?.cornerRadius = 6
        webView.layer?.masksToBounds = true
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }

        // Status label in basso — titolo pagina
        let statusFrame = NSRect(
            x: padding,
            y: padding,
            width: frame.width - padding * 2,
            height: bottomBarHeight
        )
        statusLabel = NSTextField(frame: statusFrame)
        statusLabel.isEditable = false
        statusLabel.isBordered = false
        statusLabel.drawsBackground = false
        statusLabel.textColor = NSColor(white: 0.5, alpha: 1.0)
        statusLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        statusLabel.alignment = .center
        statusLabel.lineBreakMode = .byTruncatingMiddle
        statusLabel.autoresizingMask = [.width]

        super.init()

        urlField.delegate = self
        webView.navigationDelegate = self

        panel.contentView?.addSubview(urlField)
        panel.contentView?.addSubview(webView)
        panel.contentView?.addSubview(statusLabel)

        navigateTo(urlString)
    }

    // MARK: - Navigazione

    func navigateTo(_ input: String) {
        var str = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.isEmpty { return }

        // Aggiungi schema se mancante
        if !str.contains("://") {
            if str.contains(".") && !str.contains(" ") {
                str = "https://" + str
            } else {
                // Cerca su Google
                let query = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? str
                str = "https://www.google.com/search?q=" + query
            }
        }

        guard let url = URL(string: str) else { return }
        webView.load(URLRequest(url: url))
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        statusLabel.stringValue = "Caricamento..."
        if let url = webView.url?.absoluteString {
            urlField.stringValue = url
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let title = webView.title ?? ""
        let url = webView.url?.absoluteString ?? ""
        statusLabel.stringValue = title.isEmpty ? url : title
        urlField.stringValue = url
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        statusLabel.stringValue = "Errore: \(error.localizedDescription)"
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        statusLabel.stringValue = "Errore: \(error.localizedDescription)"
    }

    // Permetti navigazione a qualsiasi URL (incluso http://localhost per DevTools)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    // MARK: - NSTextFieldDelegate (URL bar)

    func control(_ control: NSControl, textView: NSTextView,
                 doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            navigateTo(urlField.stringValue)
            panel.makeFirstResponder(webView)
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            panel.makeFirstResponder(webView)
            return true
        }
        return false
    }

    func show() {
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeFirstResponder(webView)
    }

    func currentURL() -> String {
        return webView.url?.absoluteString ?? urlField.stringValue
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var viewController: BrowserViewController!
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments

        // URL: argomento > ultimo usato > default
        var url: String
        if args.count > 1 {
            url = args[1]
        } else if let last = try? String(contentsOfFile: "/tmp/bigide-browser-last", encoding: .utf8) {
            let trimmed = last.trimmingCharacters(in: .whitespacesAndNewlines)
            url = trimmed.isEmpty ? "https://www.google.com" : trimmed
        } else {
            url = "https://www.google.com"
        }

        viewController = BrowserViewController(urlString: url)
        viewController.show()

        // Monitor tastiera e mouse
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown]
        ) { [weak self] event in
            guard let self = self else { return event }

            if event.type == .keyDown {
                let keyCode = event.keyCode
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let hasCmd = flags.contains(.command)

                // Esc → se URL field attivo: unfocus. Altrimenti: chiudi
                if keyCode == 53 {
                    if self.viewController.urlField.currentEditor() != nil {
                        self.viewController.panel.makeFirstResponder(self.viewController.webView)
                        return nil
                    }
                    self.writeLastURL()
                    NSApp.terminate(nil)
                    return nil
                }

                // Cmd+W → chiudi
                if hasCmd && event.charactersIgnoringModifiers == "w" {
                    self.writeLastURL()
                    NSApp.terminate(nil)
                    return nil
                }

                // Cmd+L → focus URL bar e seleziona tutto
                if hasCmd && event.charactersIgnoringModifiers == "l" {
                    self.viewController.panel.makeFirstResponder(self.viewController.urlField)
                    self.viewController.urlField.selectText(nil)
                    return nil
                }

                // Cmd+R → ricarica pagina
                if hasCmd && event.charactersIgnoringModifiers == "r" {
                    self.viewController.webView.reload()
                    return nil
                }

                // Cmd+← → indietro
                if hasCmd && keyCode == 123 {
                    self.viewController.webView.goBack()
                    return nil
                }

                // Cmd+→ → avanti
                if hasCmd && keyCode == 124 {
                    self.viewController.webView.goForward()
                    return nil
                }
            } else if event.type == .leftMouseDown {
                // Click fuori da webview e URL field → chiudi
                let loc = event.locationInWindow
                let webFrame = self.viewController.webView.frame
                let urlFrame = self.viewController.urlField.frame
                if !webFrame.contains(loc) && !urlFrame.contains(loc) {
                    self.writeLastURL()
                    NSApp.terminate(nil)
                    return nil
                }
            }
            return event
        }
    }

    private func writeLastURL() {
        let url = viewController.currentURL()
        if !url.isEmpty {
            try? url.write(toFile: "/tmp/bigide-browser-last", atomically: true, encoding: .utf8)
        }
    }
}

// --- Main ---
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
