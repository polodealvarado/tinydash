# Your Nymiz

What needs my attention today — agenda, unread email and Slack — in one place, one click away in the macOS menu bar.

- **Dashboard:** https://example.com/dashboard (source: `dashboard/your-nymiz.html`)
- **Menu bar app:** `macos-app/`

## Install the menu bar app

```bash
xcode-select --install     # once, if swiftc is missing
cd macos-app
./build.sh                 # builds, installs in /Applications and opens it
```

Click the ghost in the menu bar to open the dashboard. Right-click for Refresh, Open in browser, Diagnostics…, Open at login and Quit.

See `CLAUDE.md` for how everything fits together.
