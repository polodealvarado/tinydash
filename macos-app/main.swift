// Your Nymiz — menu bar app for macOS
// Left-click the icon: today's agenda, tasks, unread email and Slack in a popover.
// Right-click: Sync now · Open at login · Quit.
// Talks to Google and Slack directly (no claude.ai). Secrets live in the Keychain;
// tasks and the last sync live in ~/Library/Application Support/YourNymiz/.

import Cocoa
import WebKit
import ServiceManagement
import Network
import CryptoKit

let POPOVER_SIZE = NSSize(width: 460, height: 680)
// ponytail: one sync a day (first check after SYNC_HOUR, or at launch). Lower AUTO_CHECK / add an interval if that's too stale.
let SYNC_HOUR = 7
let AUTO_CHECK: TimeInterval = 15 * 60
let GOOGLE_SCOPES = "https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/gmail.readonly"
let GMAIL_QUERY = "in:inbox is:unread newer_than:3d -category:promotions -category:social -category:forums"

// MARK: storage

let dataDir: URL = {
    let d = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("YourNymiz")
    try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
    return d
}()
func readJSON(_ name: String) -> Any? {
    (try? Data(contentsOf: dataDir.appendingPathComponent(name))).flatMap { try? JSONSerialization.jsonObject(with: $0) }
}
func writeJSON(_ name: String, _ value: Any) {
    if let d = try? JSONSerialization.data(withJSONObject: value) { try? d.write(to: dataDir.appendingPathComponent(name), options: .atomic) }
}

// All secrets in one Keychain item: googleClientId, googleClientSecret, googleRefresh, slackToken.
enum Keychain {
    static let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                      kSecAttrService as String: "com.nymiz.yournymiz", kSecAttrAccount as String: "secrets"]
    static func load() -> [String: String] {
        var q = base; q[kSecReturnData as String] = true
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data else { return [:] }
        return ((try? JSONSerialization.jsonObject(with: d)) as? [String: String]) ?? [:]
    }
    static func save(_ s: [String: String]) {
        SecItemDelete(base as CFDictionary)
        guard !s.isEmpty, let d = try? JSONSerialization.data(withJSONObject: s) else { return }
        var q = base; q[kSecValueData as String] = d
        SecItemAdd(q as CFDictionary, nil)
    }
}

// MARK: HTTP

struct APIError: LocalizedError {
    let message: String; var status = 0
    var errorDescription: String? { message }
}
func makeURL(_ base: String, _ items: [(String, String)]) -> URL {
    var c = URLComponents(string: base)!
    c.queryItems = items.map { URLQueryItem(name: $0.0, value: $0.1) }
    return c.url!
}
func formPost(_ base: String, _ fields: [(String, String)]) -> URLRequest {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
    var r = URLRequest(url: URL(string: base)!)
    r.httpMethod = "POST"
    r.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    r.httpBody = fields.map { "\($0.0)=\($0.1.addingPercentEncoding(withAllowedCharacters: allowed)!)" }.joined(separator: "&").data(using: .utf8)
    return r
}
func send(_ r: URLRequest) async throws -> [String: Any] {
    let (data, resp) = try await URLSession.shared.data(for: r)
    let obj = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any]) ?? [:]
    let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
    if code >= 400 {
        let msg = ((obj["error"] as? [String: Any])?["message"] as? String) ?? (obj["error_description"] as? String) ?? (obj["error"] as? String) ?? "HTTP \(code)"
        throw APIError(message: msg, status: code)
    }
    return obj
}
func getJSON(_ url: URL, token: String) async throws -> [String: Any] {
    var r = URLRequest(url: url)
    r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return try await send(r)
}
func base64URL(_ d: Data) -> String {
    d.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
}
func randomURLSafe(_ bytes: Int) -> String { base64URL(Data((0..<bytes).map { _ in UInt8.random(in: 0...255) })) }
func ymd(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: d) }

// MARK: Google OAuth (desktop "loopback" flow with PKCE: browser → http://127.0.0.1:<port>/?code=…)

func loopbackCode(state: String, authURL: @escaping (String) -> URL) async throws -> (code: String, redirect: String) {
    let params = NWParameters.tcp
    params.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
    let listener = try NWListener(using: params)
    return try await withCheckedThrowingContinuation { cont in
        var finished = false
        var redirect = ""
        func finish(_ r: Result<(code: String, redirect: String), Error>) {
            if finished { return }
            finished = true
            listener.cancel()
            cont.resume(with: r)
        }
        listener.stateUpdateHandler = { st in
            switch st {
            case .ready:
                redirect = "http://127.0.0.1:\(listener.port!.rawValue)"
                NSWorkspace.shared.open(authURL(redirect))
            case .failed(let e): finish(.failure(e))
            default: break
            }
        }
        listener.newConnectionHandler = { conn in
            conn.start(queue: .main)
            conn.receive(minimumIncompleteLength: 1, maximumLength: 16384) { data, _, _, _ in
                // First line: "GET /?code=…&state=… HTTP/1.1"
                let line = data.flatMap { String(data: $0, encoding: .utf8) }?.components(separatedBy: "\r\n").first ?? ""
                let path = line.split(separator: " ").dropFirst().first.map(String.init) ?? ""
                let items = URLComponents(string: "http://x" + path)?.queryItems ?? []
                func v(_ n: String) -> String? { items.first { $0.name == n }?.value }
                let code = v("state") == state ? v("code") : nil
                let body = code != nil ? "Signed in. You can close this tab and go back to Your Nymiz."
                                       : "Sign-in failed (\(v("error") ?? "unexpected reply")). Close this tab and try again."
                let resp = "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nConnection: close\r\n\r\n" + body
                conn.send(content: Data(resp.utf8), completion: .contentProcessed { _ in conn.cancel() })
                if let code = code { finish(.success((code, redirect))) }
                else if let e = v("error") { finish(.failure(APIError(message: "Google sign-in: \(e)"))) }
            }
        }
        listener.start(queue: .main)
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { finish(.failure(APIError(message: "Google sign-in timed out."))) }
    }
}

// threads.list only returns ids; fetch each thread's headers + snippet in parallel.
func fetchGmail(_ token: String) async throws -> [String: Any] {
    let base = "https://gmail.googleapis.com/gmail/v1/users/me/threads"
    let list = try await getJSON(makeURL(base, [("q", GMAIL_QUERY), ("maxResults", "25")]), token: token)
    let ids = ((list["threads"] as? [[String: Any]]) ?? []).compactMap { $0["id"] as? String }
    let threads = try await withThrowingTaskGroup(of: (Int, [String: Any]).self) { group in
        for (i, id) in ids.enumerated() {
            group.addTask {
                (i, try await getJSON(makeURL(base + "/" + id, [("format", "metadata"), ("metadataHeaders", "Subject"),
                                                                ("metadataHeaders", "From"), ("metadataHeaders", "Date")]), token: token))
            }
        }
        var out: [(Int, [String: Any])] = []
        for try await r in group { out.append(r) }
        return out.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
    return ["threads": threads, "resultSizeEstimate": list["resultSizeEstimate"] ?? 0]
}

// MARK: app

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var webView: WKWebView!
    private var secrets = Keychain.load()
    private var tasks: [Any] = (readJSON("tasks.json") as? [Any]) ?? []
    private var lastSync = readJSON("sync.json") as? [String: Any]
    private var syncing = false
    private var googleAccess: (token: String, expires: Date)?
    private var pageDay = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        installEditMenu()

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "nymiz")
        webView = WKWebView(frame: NSRect(origin: .zero, size: POPOVER_SIZE), configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        if #available(macOS 13.3, *) { webView.isInspectable = true }   // right-click → Inspect Element
        loadPage()

        let controller = NSViewController()
        controller.view = webView
        popover.contentViewController = controller
        popover.contentSize = POPOVER_SIZE
        popover.behavior = .transient
        popover.animates = true

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = makeStatusIcon()
            button.toolTip = "Your Nymiz"
            button.target = self
            button.action = #selector(statusClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Daily auto-sync: at launch, every AUTO_CHECK and on wake, sync if it hasn't run today.
        maybeAutoSync(launch: true)
        Timer.scheduledTimer(withTimeInterval: AUTO_CHECK, repeats: true) { _ in Task { @MainActor in self.maybeAutoSync() } }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in self.maybeAutoSync() }
        }
    }

    private func loadPage() {
        let page = Bundle.main.url(forResource: "index", withExtension: "html")!
        pageDay = ymd(Date())
        webView.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
    }

    // MARK: sync

    private func maybeAutoSync(launch: Bool = false) {
        let last = (lastSync?["at"] as? Double).map { Date(timeIntervalSince1970: $0 / 1000) }
        let syncedToday = last.map { Calendar.current.isDateInToday($0) } ?? false
        if !syncedToday && (launch || Calendar.current.component(.hour, from: Date()) >= SYNC_HOUR) {
            Task { await sync() }
        }
    }

    private func sync() async {
        guard !syncing, secrets["googleRefresh"] != nil || secrets["slackToken"] != nil else { return }
        syncing = true
        push()
        async let g = runGoogle()
        async let s = runSlack()
        let (gd, ge) = await g, (sd, se) = await s
        var result: [String: Any] = ["at": Date().timeIntervalSince1970 * 1000]
        result.merge(gd) { a, _ in a }
        result.merge(sd) { a, _ in a }
        var err: [String: String] = [:]
        err["google"] = ge
        err["slack"] = se
        result["err"] = err
        lastSync = result
        writeJSON("sync.json", result)
        syncing = false
        if pageDay != ymd(Date()) { loadPage() } else { push() }   // a new day: reload so "today" moves on
    }

    private func runGoogle() async -> ([String: Any], String?) {
        guard secrets["googleRefresh"] != nil else { return ([:], nil) }
        do {
            let token = try await googleToken()
            let start = Calendar.current.startOfDay(for: Date())
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            let iso = ISO8601DateFormatter()
            async let cal = getJSON(makeURL("https://www.googleapis.com/calendar/v3/calendars/primary/events", [
                ("timeMin", iso.string(from: start)), ("timeMax", iso.string(from: end)), ("singleEvents", "true"),
                ("orderBy", "startTime"), ("maxResults", "50"), ("timeZone", TimeZone.current.identifier)]), token: token)
            async let mail = fetchGmail(token)
            return (["cal": try await cal, "mail": try await mail], nil)
        } catch {
            return ([:], error.localizedDescription)
        }
    }

    private func googleToken() async throws -> String {
        if let a = googleAccess, a.expires > Date().addingTimeInterval(60) { return a.token }
        guard let id = secrets["googleClientId"], let secret = secrets["googleClientSecret"], let refresh = secrets["googleRefresh"] else {
            throw APIError(message: "Google isn't connected.")
        }
        let t: [String: Any]
        do {
            t = try await send(formPost("https://oauth2.googleapis.com/token", [
                ("client_id", id), ("client_secret", secret), ("refresh_token", refresh), ("grant_type", "refresh_token")]))
        } catch let e as APIError where e.status == 400 || e.status == 401 {
            throw APIError(message: "Google access expired or was revoked (\(e.message)). Disconnect and connect Google again in Settings.")
        }
        guard let access = t["access_token"] as? String else { throw APIError(message: "Google didn't return an access token.") }
        googleAccess = (access, Date().addingTimeInterval((t["expires_in"] as? Double) ?? 3600))
        return access
    }

    private func connectGoogle(clientId: String, clientSecret: String) async {
        do {
            let verifier = randomURLSafe(32)
            let challenge = base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
            let state = randomURLSafe(16)
            let (code, redirect) = try await loopbackCode(state: state) { redirect in
                makeURL("https://accounts.google.com/o/oauth2/v2/auth", [
                    ("client_id", clientId), ("redirect_uri", redirect), ("response_type", "code"), ("scope", GOOGLE_SCOPES),
                    ("code_challenge", challenge), ("code_challenge_method", "S256"), ("access_type", "offline"),
                    ("prompt", "consent"), ("state", state)])
            }
            let t = try await send(formPost("https://oauth2.googleapis.com/token", [
                ("code", code), ("client_id", clientId), ("client_secret", clientSecret), ("redirect_uri", redirect),
                ("grant_type", "authorization_code"), ("code_verifier", verifier)]))
            guard let refresh = t["refresh_token"] as? String else { throw APIError(message: "Google didn't return a refresh token.") }
            secrets["googleClientId"] = clientId
            secrets["googleClientSecret"] = clientSecret
            secrets["googleRefresh"] = refresh
            Keychain.save(secrets)
            if let access = t["access_token"] as? String {
                googleAccess = (access, Date().addingTimeInterval((t["expires_in"] as? Double) ?? 3600))
            }
            push()
            await sync()
        } catch {
            alert("Couldn't connect Google", error.localizedDescription)
        }
    }

    private func runSlack() async -> ([String: Any], String?) {
        guard let token = secrets["slackToken"] else { return ([:], nil) }
        func slack(_ method: String, _ q: [(String, String)]) async throws -> [String: Any] {
            let r = try await getJSON(makeURL("https://slack.com/api/" + method, q), token: token)
            guard r["ok"] as? Bool == true else {
                let e = (r["error"] as? String) ?? "unknown error"
                throw APIError(message: "Slack: \(e)" + (["invalid_auth", "token_revoked", "not_authed", "missing_scope"].contains(e) ? ". Check the token in Settings." : ""))
            }
            return r
        }
        do {
            let me = (try await slack("auth.test", []))["user_id"] as? String ?? ""
            let day = Calendar.current.startOfDay(for: Date())
            let yesterday = ymd(day.addingTimeInterval(-86400)), threeAgo = ymd(day.addingTimeInterval(-3 * 86400))
            // Slack's after: is exclusive: after:<yesterday> = today.
            async let dm = slack("search.messages", [("query", "to:<@\(me)> after:\(yesterday)"), ("count", "20"), ("sort", "timestamp")])
            async let men = slack("search.messages", [("query", "<@\(me)> -is:dm after:\(threeAgo)"), ("count", "15"), ("sort", "timestamp")])
            return (["slackDm": try await dm, "slackMen": try await men, "me": me], nil)
        } catch {
            return ([:], error.localizedDescription)
        }
    }

    // Whole state to the page; it re-renders everything from it.
    private func push() {
        let state: [String: Any] = ["google": secrets["googleRefresh"] != nil, "slack": secrets["slackToken"] != nil,
                                    "syncing": syncing, "tasks": tasks, "sync": lastSync ?? NSNull()]
        guard let d = try? JSONSerialization.data(withJSONObject: state), let json = String(data: d, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.nymizUpdate && window.nymizUpdate(\(json))")
    }

    // Messages from the page: window.webkit.messageHandlers.nymiz.postMessage({cmd, …})
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let m = message.body as? [String: Any], let cmd = m["cmd"] as? String else { return }
        switch cmd {
        case "ready": push()
        case "sync": Task { await sync() }
        case "saveTasks":
            tasks = (m["tasks"] as? [Any]) ?? []
            writeJSON("tasks.json", tasks)
        case "connectGoogle":
            guard let id = m["clientId"] as? String, let secret = m["clientSecret"] as? String else { return }
            Task { await connectGoogle(clientId: id, clientSecret: secret) }
        case "setSlackToken":
            secrets["slackToken"] = m["token"] as? String
            Keychain.save(secrets)
            push()
            Task { await sync() }
        case "disconnect":
            if m["which"] as? String == "google" {
                ["googleRefresh", "googleClientId", "googleClientSecret"].forEach { secrets.removeValue(forKey: $0) }
                googleAccess = nil
            } else {
                secrets.removeValue(forKey: "slackToken")
            }
            Keychain.save(secrets)
            push()
        default: break
        }
    }

    // MARK: status item

    @objc private func statusClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: syncing ? "Syncing…" : "Sync now", action: #selector(syncNow), keyEquivalent: "r")
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

    @objc private func syncNow() { Task { await sync() } }
    @objc private func quit() { NSApp.terminate(nil) }

    @available(macOS 13.0, *)
    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            alert("Couldn't change Open at login", "Move Your Nymiz.app to the Applications folder and try again.\n\n\(error.localizedDescription)")
        }
    }

    private func alert(_ title: String, _ text: String) {
        let a = NSAlert()
        a.messageText = title
        a.informativeText = text
        NSApp.activate(ignoringOtherApps: true)
        a.runModal()
    }

    // Standard Edit menu so ⌘C / ⌘V / ⌘A work in the popover (e.g. pasting the Slack token).
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

    // MARK: web view — the page is local; every web link opens in your browser.

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        if let url = action.request.url, url.scheme == "http" || url.scheme == "https" {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = action.request.url { NSWorkspace.shared.open(url) }
        return nil
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { loadPage() }
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

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
    app.run()
}
