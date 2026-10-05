# Releasing Tinydash

Tinydash is distributed as a universal macOS app through GitHub Releases and the [Homebrew tap](https://github.com/polodealvarado/homebrew-tinydash).

GitHub Actions must be enabled for the account before the workflows can run. The first Homebrew release, `v2.3.0`, was built and verified locally because Actions was disabled for the maintainer account.

## Release a version

1. Update `CFBundleShortVersionString` in `macos-app/Info.plist` to a three-part version such as `2.3.0` and increment `CFBundleVersion`.
2. Update the changelog and commit the changes to `main`.
3. Tag the same commit and push the tag:

   ```sh
   git tag -a v2.3.0 -m 'Tinydash 2.3.0'
   git push origin main v2.3.0
   ```

The **Release** workflow builds both `arm64` and `x86_64` slices using the minimum macOS version declared in the app's plist. It verifies the universal binary and its code signature, creates a ZIP and SHA-256 checksum, uploads them to a draft release, then publishes it. A mismatched tag or an existing release stops the workflow.

Published archives must remain immutable: create a new version for corrections instead of replacing an existing download. Homebrew pins the archive checksum.

The tap's **Update cask** workflow checks for a new release daily. Run it manually after publishing if the cask should update immediately. It downloads the ZIP, verifies its published checksum, and commits the new version to the tap. No token shared between repositories is needed.

## Build a package locally

```sh
./scripts/package.sh
```

Outputs are written to `dist/`, which is excluded from Git. Packaging does not install or launch the app.

## Publish when Actions is unavailable

With the release tag already pushed, build locally and publish using an authenticated GitHub CLI:

```sh
TINYDASH_RELEASE_TAG=v2.3.0 ./scripts/package.sh
gh release create v2.3.0 --verify-tag --draft --title 'Tinydash v2.3.0' --notes-file .github/release-notes.md
gh release upload v2.3.0 dist/Tinydash-2.3.0-universal.zip dist/Tinydash-2.3.0-universal.zip.sha256
gh release edit v2.3.0 --draft=false
```

Use the new version number throughout; do not overwrite an existing release. In a checkout of `homebrew-tinydash`, update the cask manually:

```sh
python3 scripts/update-cask.py
git add Casks/tinydash.rb
git commit -m 'chore: update Tinydash cask'
git push origin main
```

## Signing status

Current releases use ad hoc signing. They are not notarized by Apple. The cask, release notes, and README disclose this limitation; Homebrew installation does not guarantee that Gatekeeper will allow first launch.

When an Apple Developer membership is available, local packaging supports a Developer ID certificate and a previously configured `notarytool` Keychain profile:

```sh
TINYDASH_SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
TINYDASH_NOTARY_PROFILE='tinydash-notary' \
./scripts/package.sh
```

This enables the hardened runtime, submits the app for notarization, staples the accepted ticket, and packages the stapled app. Never commit certificates or credentials. The GitHub workflow currently creates ad hoc builds; configure a protected signing environment before using it for notarized releases, and update the release notes and cask signing notice at that time.

## Validate a Homebrew release

```sh
brew tap polodealvarado/tinydash
brew style --cask polodealvarado/tinydash/tinydash
brew fetch --cask polodealvarado/tinydash/tinydash
brew install --cask polodealvarado/tinydash/tinydash
```

Use a clean Mac or an isolated app directory for installation checks when a manually installed copy already exists. Never remove user data as part of a release check.
