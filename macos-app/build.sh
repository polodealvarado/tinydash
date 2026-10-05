#!/bin/bash
# Build Tinydash; --build-only skips installation; --universal includes both Mac architectures.
set -euo pipefail
cd "$(dirname "$0")"

BUILD_ONLY=false
UNIVERSAL=false
for arg in "$@"; do
  case "$arg" in
    --build-only) BUILD_ONLY=true ;;
    --universal) UNIVERSAL=true ;;
    *) echo "Usage: ./build.sh [--build-only] [--universal]" >&2; exit 1 ;;
  esac
done
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
MIN_MACOS=$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' Info.plist)
ARCHS=("$(uname -m)")
if $UNIVERSAL; then ARCHS=(arm64 x86_64); fi
for arch in "${ARCHS[@]}"; do
  swiftc -O -target "${arch}-apple-macosx${MIN_MACOS}" main.swift PencilIcon.swift \
    -o "$STAGING/Tinydash-$arch" \
    -framework Cocoa -framework WebKit -framework ServiceManagement -framework Network
done
if $UNIVERSAL; then
  lipo -create "$STAGING/Tinydash-arm64" "$STAGING/Tinydash-x86_64" \
    -output "$BUNDLE/Contents/MacOS/Tinydash"
else
  cp "$STAGING/Tinydash-${ARCHS[0]}" "$BUNDLE/Contents/MacOS/Tinydash"
fi
cp Info.plist "$BUNDLE/Contents/Info.plist"
cp ../dashboard/index.html "$BUNDLE/Contents/Resources/index.html"
if [[ -n ${TINYDASH_SIGNING_IDENTITY:-} ]]; then
  codesign --force --options runtime --timestamp --sign "$TINYDASH_SIGNING_IDENTITY" "$BUNDLE"
else
  codesign --force --sign - "$BUNDLE"
fi
codesign --verify --deep --strict "$BUNDLE"
ditto "$BUNDLE" "$APP"

if $BUILD_ONLY; then
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
