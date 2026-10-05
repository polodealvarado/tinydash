#!/bin/bash
# Produce the immutable universal archive consumed by the Homebrew cask.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' macos-app/Info.plist)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Release versions must use major.minor.patch in Info.plist." >&2
  exit 1
fi
if [[ -n ${TINYDASH_RELEASE_TAG:-} && "$TINYDASH_RELEASE_TAG" != "v$VERSION" ]]; then
  echo "Release tag does not match Info.plist version $VERSION." >&2
  exit 1
fi
if [[ -n ${TINYDASH_SIGNING_IDENTITY:-} && -z ${TINYDASH_NOTARY_PROFILE:-} ]] ||
   [[ -z ${TINYDASH_SIGNING_IDENTITY:-} && -n ${TINYDASH_NOTARY_PROFILE:-} ]]; then
  echo "Provide both TINYDASH_SIGNING_IDENTITY and TINYDASH_NOTARY_PROFILE for notarized releases." >&2
  exit 1
fi

./macos-app/build.sh --build-only --universal
APP="macos-app/Tinydash.app"
lipo "$APP/Contents/MacOS/Tinydash" -verify_arch arm64 x86_64
mkdir -p dist
ARCHIVE="Tinydash-$VERSION-universal.zip"

if [[ -n ${TINYDASH_NOTARY_PROFILE:-} ]]; then
  NOTARY_DIR=$(mktemp -d "${TMPDIR:-/tmp}/tinydash-notary.XXXXXX")
  trap 'rm -rf "$NOTARY_DIR"' EXIT
  ditto -c -k --sequesterRsrc --keepParent "$APP" "$NOTARY_DIR/submit.zip"
  xcrun notarytool submit "$NOTARY_DIR/submit.zip" --keychain-profile "$TINYDASH_NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
fi

codesign --verify --deep --strict "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "dist/$ARCHIVE"
(cd dist && shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256")
printf 'Release package: dist/%s\n' "$ARCHIVE"
