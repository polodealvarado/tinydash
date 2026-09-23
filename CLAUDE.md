# Your Nymiz

Personal "what needs my attention today" dashboard for the user, plus a macOS menu bar app that opens it.

Human docs (Spanish) live in `docs/`: `ARQUITECTURA.md` (architecture, data shapes), `CONECTORES-Y-PUBLICACION.md` (connectors, capability manifest, publish flow), `SOLUCION-DE-PROBLEMAS.md` (troubleshooting), `HISTORIAL.md` (versions + decisions), `ROADMAP.md` (pending ideas). Keep them in sync when you change behavior: add a row to `HISTORIAL.md` for every dashboard republish or app version bump.

Talk to the user in Spanish. Dashboard UI copy stays in English.

## Parts

| Path | What it is |
|---|---|
| `dashboard/your-nymiz.html` | The dashboard page. Published as a claude.ai Artifact at https://example.com/dashboard |
| `macos-app/` | Menu bar app (Swift, AppKit + WKWebView). Ghost icon → popover that loads the artifact URL. |
| `assets/` | Ghost icon source (`ghost.svg`, 18×18 template) and a preview PNG. |

## Dashboard (`dashboard/your-nymiz.html`)

- Plain HTML/CSS/JS, no build step, no libraries. The Artifact publisher wraps it in `<html><head><body>`, so the file has no doctype/html/body tags of its own. `<title>` must stay near the top.
- UI copy is in **English**. Title: "Your Nymiz".
- Live data comes from the **claude.ai Artifact runtime**, not from direct API calls: `await window.claude.use("mcp")`, then `mcp.watchTool(server, tool, input, handler, {refetchInterval: 300000})`. This only works when the page is opened inside claude.ai by a signed-in viewer. Opening the file locally shows the "can't read your connectors" state — that is expected.
- Connectors declared in the artifact's capability manifest (must match what the page calls):
  - `Google Calendar` → `list_events` (today, `orderBy: startTime`, `timeZone`)
  - `Gmail` → `search_threads` (`in:inbox is:unread newer_than:3d -category:promotions -category:social -category:forums`)
  - `Slack` → `slack_search_public_and_private` (DMs: `to:<@U00000000> after:<yesterday>`; mentions: keyword `<@U00000000>` + `-is:dm`, last 3 days)
- Observed response shapes (from real calls):
  - Calendar: `{events:[{id, summary, start{dateTime|date}, end, htmlLink, conferenceUrl, conferenceData.videoEntryPoint.uri, attendees[{self, responseStatus}]}]}`
  - Gmail: `{threads:[{id, viewUrl, messages:[{subject, sender, snippet, date, labelIds, viewUrl}]}], resultCountEstimate}` — snippets contain HTML entities and U+034F padding; `cleanText()` strips them.
  - Slack: `{results: "<markdown report>"}` — **text, not JSON**. `normSlack()` parses blocks split on `### Result N of M`, reading `Channel:`, `Participants:`, `From:`, `Message_ts:`, `Permalink: [link](url)`, `Text:` … `---`. If Slack changes this format the section goes empty; fix the parser first.
- Per-viewer state lives in `localStorage` only (wrapped in try/catch): `radar-done-<date>` (ticked email/calendar items), `radar-slack-seen` (Slack "seen" marks, pruned after 7 days). Nothing syncs across devices.
- Theme: tokens on `:root`, dark palette under `prefers-color-scheme` guarded by `:root:not([data-theme="light"])` and again under `:root[data-theme="dark"]`. Keep that pattern.
- CSP: external scripts only from cdnjs/jsdelivr; no fetch to other hosts. Links open in a new tab.
- `renderDrive` / `normFiles` are leftovers from a removed Drive section (unused). Safe to delete.

### Publishing changes

Claude Code can't publish claude.ai Artifacts from a local shell. To update the live dashboard, ask Claude (claude.ai / Cowork) to republish `dashboard/your-nymiz.html` to the artifact URL above, keeping the same `capabilities.mcp` manifest (add the tool there if the page starts calling a new one).

## macOS app (`macos-app/`)

- Build + install: `cd macos-app && ./build.sh` (needs `xcode-select --install`). Compiles with `swiftc`, assembles `Your Nymiz.app`, ad-hoc signs, copies to `/Applications`, launches.
- `LSUIElement` = menu bar only, no Dock icon. Bundle id `com.nymiz.yournymiz`. Bump `CFBundleShortVersionString`/`CFBundleVersion` in `Info.plist` on each release.
- Icon: `makeStatusIcon()` draws the ghost as an `NSBezierPath` template image (even-odd fill for the eyes). Mirrors `assets/ghost.svg`.
- Popover: 460×680 `NSPopover` holding a `WKWebView` (default persistent data store, Safari user agent). `.transient` normally; `.applicationDefined` while signing in so it doesn't close.
- Sign-in: Google's sign-in (`accounts.google.com/gsi/...`) opens as a **real pop-up window** via `createWebViewWith` using the passed configuration, so `window.opener` works. Loading it inside the main view breaks sign-in (blank page) — don't regress this. `webViewDidClose` closes the window. After sign-in, `updateSignInState()` navigates back to the dashboard.
- Links to non-claude hosts (Gmail, Slack, Meet…) open in the default browser (`isInternal()` / `INTERNAL_HOSTS`).
- Right-click menu: Refresh, Open in browser, Diagnostics… (URL, load state, page text length, last error — with Copy), Open at login (`SMAppService`, macOS 13+), Quit.
- Web Inspector enabled (`isInspectable`, macOS 13.3+): right-click inside the popover → Inspect Element.

## Repo housekeeping

- `.git/leftovers/` holds stale lock files moved there when the repo was created from a sandbox that couldn't delete files; `.git/objects/**/tmp_obj_*` are harmless leftovers from the same step. Safe to delete both.

## Status / known issues

- v1.2: Google sign-in pop-up fix is untested on a real Mac. If Google shows "This browser or app may not be secure", sign in to claude.ai with email code instead.
- The menu bar icon has no badge/count: the app can't read connector data itself (that lives in the claude.ai session). A count would need either a native Google/Slack OAuth integration or JS→native messaging from the page (`WKScriptMessageHandler`) posting a pending count.
