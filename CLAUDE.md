# Your Nymiz

Personal "what needs my attention today" dashboard for the user, as a macOS menu bar app. Since v2.0 it is **standalone**: no claude.ai, no MCP connectors. The app calls Google and Slack directly.

Human docs (Spanish) live in `docs/`: `ARQUITECTURA.md` (architecture, bridge, API calls), `CONFIGURACION.md` (Google Cloud + Slack app setup, where data lives, sync schedule), `SOLUCION-DE-PROBLEMAS.md`, `HISTORIAL.md` (versions + decisions), `ROADMAP.md`. Keep them in sync when behavior changes; add a `HISTORIAL.md` row for every version bump.

Talk to the user in Spanish. Dashboard UI copy stays in English.

## Parts

| Path | What it is |
|---|---|
| `dashboard/index.html` | The panel. Standalone HTML/CSS/JS, no libraries. `build.sh` copies it to `Contents/Resources/index.html`. |
| `macos-app/main.swift` | Menu bar app (AppKit + WKWebView + Network + CryptoKit). OAuth, API calls, storage, daily sync. |
| `assets/` | Ghost icon source (`ghost.svg`). |

The old claude.ai artifact (https://example.com/dashboard) still exists but is no longer used by the app. Its source is in git history as `dashboard/your-nymiz.html`.

## Bridge

- Page → app: `window.webkit.messageHandlers.nymiz.postMessage({cmd})`, where `cmd` is `ready | sync | saveTasks | connectGoogle | setSlackToken | disconnect`.
- App → page: `window.nymizUpdate({google, slack, syncing, tasks, sync})`. `sync` holds **raw** API responses (`cal` = Calendar `events.list`, `mail` = `{threads:[threads.get metadata], resultSizeEstimate}`, `slackDm`/`slackMen` = `search.messages`) plus `me` and `err.{google,slack}`. The page normalizes them (`normEvents`, `normThreads`, `normSlack`).
- Tokens never reach JS. Secrets are one Keychain item (service `com.nymiz.yournymiz`, account `secrets`). `tasks.json` and `sync.json` live in `~/Library/Application Support/YourNymiz/`.

## Behavior

- Google: desktop OAuth loopback + PKCE (`loopbackCode()`), scopes `calendar.readonly gmail.readonly`, refresh token in the Keychain.
- Slack: the user pastes a user token (`xoxp-`, scope `search:read`). Queries in `runSlack()`; Slack's `after:` is exclusive.
- Sync: daily (`maybeAutoSync`: at launch, every `AUTO_CHECK`, on wake, if not synced today and hour ≥ `SYNC_HOUR`) plus Sync all / Sync now. Each sync replaces the previous one.
- Every http(s) link opens in the default browser.
- Per-viewer ticks/seen marks are still in `localStorage` (`radar-done-<date>`, `radar-slack-seen`), wrapped in try/catch.
- Theme tokens on `:root` with a dark palette under `prefers-color-scheme`. `[hidden]{display:none!important}` is required because panels set `display`.

## Build

`cd macos-app && ./build.sh`: compiles with `swiftc`, bundles `index.html`, signs ad hoc, installs to `/Applications` and launches. Bump `CFBundleShortVersionString`/`CFBundleVersion` in `Info.plist` for each release. Ad-hoc signing means a Keychain prompt after each rebuild.

## Status / known issues

- v2.0: Slack queries (`to:<@ME>`, `<@ME> -is:dm`) were ported from the MCP connector and haven't been tested against `search.messages` with a real token yet.
