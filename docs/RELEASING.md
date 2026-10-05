# Releasing Tinydash

Tinydash is distributed as a universal macOS app through GitHub Releases and the [Homebrew cask](../Casks/tinydash.rb) in this same repository.

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

After publishing, **Release** calls the reusable **Update cask** workflow. It downloads the latest stable ZIP, verifies its published checksum, and commits only `Casks/tinydash.rb` to `main`. The updater also handles releases published manually and can be rerun with **Run workflow**. Updates are serialized; a failed update can be retried without rebuilding or replacing the release archive.

The explicit workflow call is necessary because a release created with `GITHUB_TOKEN` does not trigger another workflow through a release event. All automation uses this repository's token with job-scoped `contents: write`; no cross-repository token is required. If branch protection prevents the bot from pushing, update the cask through a reviewed pull request instead of weakening the branch rule.

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

Use the new version number throughout; do not overwrite an existing release. From the root of this repository, update the cask manually:

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
brew tap --custom-remote polodealvarado/tinydash https://github.com/polodealvarado/tinydash.git
brew style --cask polodealvarado/tinydash/tinydash
brew fetch --cask polodealvarado/tinydash/tinydash
brew install --cask polodealvarado/tinydash/tinydash
```

Use a clean Mac or an isolated app directory for installation checks when a manually installed copy already exists. Never remove user data as part of a release check.

## Migrate from the former tap

The former `homebrew-tinydash` repository has been retired. App source, release scripts, and the cask are maintained here. Existing installations keep the same cask name and app identity.

```sh
brew tap --custom-remote polodealvarado/tinydash https://github.com/polodealvarado/tinydash.git
brew update
brew info --cask polodealvarado/tinydash/tinydash
```

This changes the tap's source without uninstalling the app or removing saved data. Use the explicit repository URL for new installations too; omitting it makes Homebrew look for the old `homebrew-` repository by convention.
