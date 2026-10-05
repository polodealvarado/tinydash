cask "tinydash" do
  version "2.3.0"
  sha256 "2c54c1b6166f896d0a454687a345bceb4bff8d3b504641bd41bca99454d11a8a"

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
