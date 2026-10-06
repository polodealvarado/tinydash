## Changes in 2.4.1

- Write multiline tasks in a growing, resizable editor with Expand/Compact controls.
- Press Enter for a new line, or Cmd+Enter to add a task. Unsubmitted drafts are saved locally.
- Agenda, Events left and Now/Next now use only today's events, including when older cached data is loaded.
- The configurable lookback period continues to apply to email, Slack and tasks.

## Install with Homebrew

```sh
brew tap --custom-remote polodealvarado/tinydash https://github.com/polodealvarado/tinydash.git
brew install --cask polodealvarado/tinydash/tinydash
```

The Homebrew cask is maintained in the main Tinydash repository and updated after publishing a release. The universal ZIP below supports Apple Silicon and Intel Macs running macOS 12 or later; its SHA-256 checksum is included.

**Signing status:** this build is signed ad hoc, without an Apple Developer ID certificate or Apple notarization. Homebrew can install it, but macOS Gatekeeper may prevent it from opening. Building from source is available in the repository. No security settings are changed by the installer.

Google and Slack connections require your own credentials. Local tasks work independently.
