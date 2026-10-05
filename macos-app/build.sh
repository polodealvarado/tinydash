#!/bin/bash
# Build Tinydash; --build-only skips installation and launch.
set -euo pipefail
cd "$(dirname "$0")"

if [[ $# -gt 1 || (${1:-} != "" && ${1:-} != "--build-only") ]]; then
  echo "Usage: ./build.sh [--build-only]" >&2
  exit 1
fi
if ! command -v swiftc >/dev/null 2>&1; then
  echo "Run xcode-select --install, then run this script again." >&2
  exit 1
fi

APP="Tinydash.app"
mkdir -p .build
STAGING=$(mktemp -d .build/tinydash.XXXXXX)
trap 'rm -rf "$STAGING"' EXIT
BUNDLE="$STAGING/$APP"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

echo "Building the pencil icon…"
swiftc PencilIcon.swift generate-icon.swift -o "$STAGING/generate-icon"
"$STAGING/generate-icon" "$STAGING/AppIcon.iconset"
iconutil -c icns "$STAGING/AppIcon.iconset" -o "$BUNDLE/Contents/Resources/AppIcon.icns"

echo "Compiling Tinydash…"
swiftc -O main.swift PencilIcon.swift -o "$BUNDLE/Contents/MacOS/Tinydash" \
  -framework Cocoa -framework WebKit -framework ServiceManagement -framework Network
cp Info.plist "$BUNDLE/Contents/Info.plist"
cp ../dashboard/index.html "$BUNDLE/Contents/Resources/index.html"
codesign --force --sign - "$BUNDLE"
codesign --verify --deep --strict "$BUNDLE"
ditto "$BUNDLE" "$APP"

if [[ ${1:-} == "--build-only" ]]; then
  echo "Built: $PWD/$APP"
  exit 0
fi

echo "Installing in /Applications…"
# Keep a recoverable copy when replacing the former app name.
if [[ -d "/Applications/Your Nymiz.app" ]]; then
  LEGACY_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "/Applications/Your Nymiz.app/Contents/Info.plist")
  if [[ "$LEGACY_ID" != "com.nymiz.yournymiz" ]]; then
    echo "The existing Your Nymiz app has an unexpected identifier; installation stopped." >&2
    exit 1
  fi
  pkill -x YourNymiz 2>/dev/null || true
  BACKUP_DIR="$HOME/Library/Application Support/YourNymiz/App Backups"
  mkdir -p "$BACKUP_DIR"
  mv "/Applications/Your Nymiz.app" "$BACKUP_DIR/Your Nymiz-$(date +%Y%m%d-%H%M%S).app"
fi
pkill -x Tinydash 2>/dev/null || true
ditto "$APP" "/Applications/$APP"
codesign --verify --deep --strict "/Applications/$APP"
open "/Applications/$APP"
echo "Done. Look for the pencil in your menu bar."
