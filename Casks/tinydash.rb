cask "tinydash" do
  version "2.4.1"
  sha256 "480382db3bb2b0630074d1cccb59c331612bc82bc9582162965e924c093f5278"

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
