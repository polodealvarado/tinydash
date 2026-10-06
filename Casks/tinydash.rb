cask "tinydash" do
  version "2.4.3"
  sha256 "cf08662ddadb8700dbd3f21ae9624a222592ef15865fa1424278cdfbac8cfbda"

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
