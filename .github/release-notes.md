## Changes in 2.4.3

- Open tasks are always visible, including future and overdue tasks.
- The review period filters only completed tasks. Show all includes completed items outside the period.
- Fix the appearance that new tasks were not saved when their due date was outside the review window.

## Install with Homebrew

```sh
brew tap --custom-remote polodealvarado/tinydash https://github.com/polodealvarado/tinydash.git
brew install --cask polodealvarado/tinydash/tinydash
```

The Homebrew cask is maintained in the main Tinydash repository and updated after publishing a release. The universal ZIP below supports Apple Silicon and Intel Macs running macOS 12 or later; its SHA-256 checksum is included.

**Signing status:** this build is signed ad hoc, without an Apple Developer ID certificate or Apple notarization. Homebrew can install it, but macOS Gatekeeper may prevent it from opening. Building from source is available in the repository. No security settings are changed by the installer.

Google and Slack connections require your own credentials. Local tasks work independently.
