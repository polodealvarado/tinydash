#!/bin/bash
# Builds "Your Nymiz.app" and installs it in /Applications.
# Needs Apple's command line tools (run `xcode-select --install` once if swiftc is missing).
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "swiftc not found. Run: xcode-select --install   — then run this script again."
  exit 1
fi

APP="Your Nymiz.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "Compiling…"
swiftc -O main.swift -o "$APP/Contents/MacOS/YourNymiz" \
  -framework Cocoa -framework WebKit -framework ServiceManagement

cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

echo "Installing in /Applications…"
pkill -x YourNymiz 2>/dev/null || true
rm -rf "/Applications/$APP"
ditto "$APP" "/Applications/$APP"
open "/Applications/$APP"
echo "Done. Look for the N icon in your menu bar."
