// Your Nymiz — menu bar app for macOS
// Left-click the icon: opens your Your Nymiz dashboard in a popover.
// Right-click: Refresh · Open in browser · Open at login · Quit.

import Cocoa
import WebKit
import ServiceManagement

let DASHBOARD_URL = URL(string: "https://example.com/dashboard")!
let POPOVER_SIZE = NSSize(width: 460, height: 680)
// Hosts allowed to load inside the popover (sign-in included). Everything else opens in your browser.
let INTERNAL_HOSTS = ["claude.ai", "anthropic.com", "claudeusercontent.com", "accounts.google.com"]

func isInternal(_ url: URL?) -> Bool {
    guard let host = url?.host?.lowercased() else { return true }
    return INTERNAL_HOSTS.contains { host == $0 || host.hasSuffix("." + $0) }
}

// Template icon: a ghost with two eye holes. macOS tints it for light/dark menu bars.
func makeStatusIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in   // y grows downward
        let p = NSBezierPath()
        p.move(to: NSPoint(x: 3.5, y: 8))
        // domed head
        p.curve(to: NSPoint(x: 9, y: 2.5), controlPoint1: NSPoint(x: 3.5, y: 4.96), controlPoint2: NSPoint(x: 5.96, y: 2.5))
        p.curve(to: NSPoint(x: 14.5, y: 8), controlPoint1: NSPoint(x: 12.04, y: 2.5), controlPoint2: NSPoint(x: 14.5, y: 4.96))
        // right side, then a wavy hem with three tails
        p.line(to: NSPoint(x: 14.5, y: 15.5))
        p.curve(to: NSPoint(x: 9, y: 15.5), controlPoint1: NSPoint(x: 13.3, y: 12.6), controlPoint2: NSPoint(x: 10.2, y: 12.6))
        p.curve(to: NSPoint(x: 3.5, y: 15.5), controlPoint1: NSPoint(x: 7.8, y: 12.6), controlPoint2: NSPoint(x: 4.7, y: 12.6))
        p.close()
        // eyes (cut out of the body)
        p.appendOval(in: NSRect(x: 6.3, y: 6.5, width: 1.6, height: 2.4))
        p.appendOval(in: NSRect(x: 10.1, y: 6.5, width: 1.6, height: 2.4))
        p.windingRule = .evenOdd
        NSColor.black.setFill()
        p.fill()
        return true
    }
    image.isTemplate = true
    return image
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var webView: WKWebView!
    private let statusBox = NSStackView()
    private let spinner = NSProgressIndicator()
    private let statusLabel = NSTextField(wrappingLabelWithString: "")
    private var lastError = "none"
    private var popups: [NSWindow] = []
    private var wasSigningIn = false
    private var loadStarted = Date()

    func applicationDidFinishLaunching(_ notification: Notification) {
        installEditMenu()

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()          // keeps you signed in between launches
        webView = WKWebView(frame: NSRect(origin: .zero, size: POPOVER_SIZE), configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.width, .height]
        if #available(macOS 13.3, *) { webView.isInspectable = true }   // right-click → Inspect Element

        // Container: web view + a status overlay shown while loading or on error
        let container = NSView(frame: NSRect(origin: .zero, size: POPOVER_SIZE))
        webView.frame = container.bounds
        container.addSubview(webView)

        spinner.style = .spinning
        spinner.controlSize = .regular
        statusLabel.alignment = .center
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.preferredMaxLayoutWidth = POPOVER_SIZE.width - 60
        statusBox.orientation = .vertical
        statusBox.spacing = 12
        statusBox.addArrangedSubview(spinner)
        statusBox.addArrangedSubview(statusLabel)
        statusBox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusBox)
        NSLayoutConstraint.activate([
            statusBox.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            statusBox.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            statusBox.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, constant: -40)
        ])

        loadDashboard()

        let controller = NSViewController()
        controller.view = container
        popover.contentViewController = controller
        popover.contentSize = POPOVER_SIZE
        popover.behavior = .transient                  // closes when you click elsewhere
        popover.animates = true

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = makeStatusIcon()
            button.toolTip = "Your Nymiz"
            button.target = self
            button.action = #selector(statusClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    // MARK: status item

    @objc private func statusClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Refresh", action: #selector(refresh), keyEquivalent: "r")
        menu.addItem(withTitle: "Open in browser", action: #selector(openInBrowser), keyEquivalent: "o")
        menu.addItem(withTitle: "Diagnostics…", action: #selector(showDiagnostics), keyEquivalent: "")
        if #available(macOS 13.0, *) {
            let login = NSMenuItem(title: "Open at login", action: #selector(toggleLoginItem), keyEquivalent: "")
            login.state = SMAppService.mainApp.status == .enabled ? .on : .off
            menu.addItem(login)
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Your Nymiz", action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil                          // keep left-click opening the popover
    }

    private func loadDashboard() {
        loadStarted = Date()
        setStatus("Loading Your Nymiz…", busy: true)
        webView.load(URLRequest(url: DASHBOARD_URL))
    }

    private func setStatus(_ text: String?, busy: Bool = false) {
        if let text = text {
            statusLabel.stringValue = text
            statusBox.isHidden = false
            if busy { spinner.isHidden = false; spinner.startAnimation(nil) } else { spinner.stopAnimation(nil); spinner.isHidden = true }
        } else {
            spinner.stopAnimation(nil)
            statusBox.isHidden = true
        }
    }

    @objc private func refresh() { loadDashboard() }

    @objc private func showDiagnostics() {
        webView.evaluateJavaScript("[document.readyState, document.title, (document.body ? document.body.innerText.length : -1), document.querySelectorAll('iframe').length].join(' | ')") { result, error in
            let page = (result as? String) ?? "JS error: \(error?.localizedDescription ?? "unknown")"
            let text = """
            URL: \(self.webView.url?.absoluteString ?? "none")
            Loading: \(self.webView.isLoading) · progress \(Int(self.webView.estimatedProgress * 100))%
            Page (state | title | text length | iframes): \(page)
            Last error: \(self.lastError)
            """
            let alert = NSAlert()
            alert.messageText = "Your Nymiz diagnostics"
            alert.informativeText = text
            alert.addButton(withTitle: "Copy")
            alert.addButton(withTitle: "Close")
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
        }
    }
    @objc private func openInBrowser() { NSWorkspace.shared.open(DASHBOARD_URL) }
    @objc private func quit() { NSApp.terminate(nil) }

    @available(macOS 13.0, *)
    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't change Open at login"
            alert.informativeText = "Move Your Nymiz.app to the Applications folder and try again.\n\n\(error.localizedDescription)"
            alert.runModal()
        }
    }

    // Standard Edit menu so ⌘C / ⌘V / ⌘A work in the popover (e.g. when signing in).
    private func installEditMenu() {
        let main = NSMenu()
        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        main.addItem(editItem)
        NSApp.mainMenu = main
    }

    // MARK: web view

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard webView === self.webView else { return }
        updateSignInState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView === self.webView else { return }      // ignore the sign-in pop-up
        updateSignInState()
        setStatus(nil)
        // If the page is still empty a few seconds after loading, say so instead of showing a blank panel.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self, !self.webView.isLoading else { return }
            self.webView.evaluateJavaScript("(document.body ? document.body.innerText.trim().length : 0) + document.querySelectorAll('iframe').length") { result, _ in
                if let n = result as? Int, n == 0 {
                    self.lastError = "page loaded but stayed empty (\(self.webView.url?.absoluteString ?? "no URL"))"
                    self.setStatus("The page loaded but stayed empty.\nRight-click the ghost → Diagnostics… and send me what it says.")
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard webView === self.webView else { return }
        showLoadError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard webView === self.webView else { return }
        showLoadError(error)
    }

    private func showLoadError(_ error: Error) {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }   // a redirect, not a failure
        lastError = "\(ns.domain) \(ns.code): \(ns.localizedDescription)"
        setStatus("Couldn't load the dashboard.\n\(ns.localizedDescription)\n\nRight-click the ghost → Refresh to try again.")
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        guard webView === self.webView else { return }
        lastError = "web content process terminated"
        loadDashboard()
    }

    // Links to Gmail, Slack, Calendar, Meet… open in your normal browser.
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if webView === self.webView, action.navigationType == .linkActivated, let url = action.request.url, !isInternal(url) {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // target="_blank" links and sign-in pop-ups.
    // Links to Gmail, Slack… open in your browser. Sign-in pop-ups (Google) get a real small window
    // linked to the dashboard, so Google can report back to claude.ai when you finish signing in.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = action.request.url, !isInternal(url) {
            NSWorkspace.shared.open(url)
            return nil
        }
        let w = CGFloat(truncating: windowFeatures.width ?? 480)
        let h = CGFloat(truncating: windowFeatures.height ?? 640)
        let popupView = WKWebView(frame: NSRect(x: 0, y: 0, width: w, height: h), configuration: configuration)
        popupView.customUserAgent = webView.customUserAgent
        popupView.uiDelegate = self
        popupView.navigationDelegate = self

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: w, height: h),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "Sign in — Your Nymiz"
        window.contentView = popupView
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        popups.append(window)
        return popupView
    }

    // Google closes its pop-up with window.close() when sign-in is done.
    func webViewDidClose(_ webView: WKWebView) {
        if let window = popups.first(where: { $0.contentView === webView }) {
            window.close()
            popups.removeAll { $0 === window }
        }
    }

    // While you're signing in the panel stays open (clicking the Google window won't close it);
    // once you're in, it jumps straight to the dashboard and goes back to closing on outside clicks.
    private func updateSignInState() {
        guard let url = webView.url else { return }
        let host = url.host?.lowercased() ?? ""
        let onClaude = host == "claude.ai" || host.hasSuffix(".claude.ai")
        let signingIn = !onClaude || url.path.hasPrefix("/login") || url.path.hasPrefix("/magic-link")
        popover.behavior = signingIn ? .applicationDefined : .transient
        if signingIn {
            wasSigningIn = true
        } else if wasSigningIn && !url.path.hasPrefix("/artifact") {
            wasSigningIn = false
            loadDashboard()
        } else if url.path.hasPrefix("/artifact") {
            wasSigningIn = false
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
app.run()
