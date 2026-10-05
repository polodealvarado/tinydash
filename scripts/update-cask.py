#!/usr/bin/env python3
"""Update the cask from a published release after checking its actual ZIP hash."""
import hashlib
import json
import os
from pathlib import Path
import re
import urllib.request

REPO = "polodealvarado/tinydash"
headers = {"Accept": "application/vnd.github+json", "User-Agent": "tinydash-homebrew"}
if os.environ.get("GH_TOKEN"):
    headers["Authorization"] = "Bearer " + os.environ["GH_TOKEN"]
request = urllib.request.Request(f"https://api.github.com/repos/{REPO}/releases/latest", headers=headers)
with urllib.request.urlopen(request, timeout=30) as response:
    release = json.load(response)
match = re.fullmatch(r"v(\d+\.\d+\.\d+)", release["tag_name"])
if not match or release["draft"] or release["prerelease"]:
    raise SystemExit("Expected a published stable semantic version.")
version = match[1]
archive_name = f"Tinydash-{version}-universal.zip"
expected_url = f"https://github.com/{REPO}/releases/download/v{version}/{archive_name}"
assets = {asset["name"]: asset for asset in release["assets"]}
for name in [archive_name, archive_name + ".sha256"]:
    expected = expected_url + (".sha256" if name.endswith(".sha256") else "")
    if name not in assets or assets[name]["browser_download_url"] != expected:
        raise SystemExit("The release is missing its archive or checksum.")
with urllib.request.urlopen(expected_url + ".sha256", timeout=30) as response:
    checksum = response.read().decode().strip().split()
if len(checksum) != 2 or checksum[1] != archive_name or not re.fullmatch(r"[0-9a-f]{64}", checksum[0]):
    raise SystemExit("Invalid checksum manifest.")
digest = hashlib.sha256()
with urllib.request.urlopen(expected_url, timeout=120) as response:
    for block in iter(lambda: response.read(1024 * 1024), b""):
        digest.update(block)
if digest.hexdigest() != checksum[0]:
    raise SystemExit("Archive does not match the published checksum.")

root = Path(__file__).resolve().parents[1]
cask_path = root / "Casks/tinydash.rb"
if cask_path.exists():
    previous = cask_path.read_text()
    current = re.search(r'version "(\d+\.\d+\.\d+)"', previous)
    if current and tuple(map(int, current[1].split('.'))) > tuple(map(int, version.split('.'))):
        raise SystemExit("Refusing to downgrade the cask.")
    old_digest = re.search(r'sha256 "([0-9a-f]{64})"', previous)
    if current and current[1] == version and old_digest and old_digest[1] != digest.hexdigest():
        raise SystemExit("Published archive changed for the same version; create a new release.")
cask = '''cask "tinydash" do
  version "%s"
  sha256 "%s"

  url "https://github.com/polodealvarado/tinydash/releases/download/v#{version}/Tinydash-#{version}-universal.zip"
  name "Tinydash"
  desc "Menu bar dashboard for your calendar, tasks, email, and Slack"
  homepage "https://github.com/polodealvarado/tinydash"

  depends_on macos: :monterey

  app "Tinydash.app"

  uninstall quit: "com.nymiz.yournymiz"

  caveats <<~EOS
    Tinydash is signed ad hoc and is not notarized by Apple.
    macOS Gatekeeper may prevent the app from opening.
    A source build is available from the project repository.
  EOS
end
''' % (version, digest.hexdigest())
cask_path.parent.mkdir(parents=True, exist_ok=True)
cask_path.write_text(cask)
print(f"Cask ready: Tinydash {version} (SHA-256 verified)")
