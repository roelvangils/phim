cask "phim" do
  version "0.3.0"
  sha256 "7481aa46ba29d9eaae3e222a0723ce6450ba80eceeaf8048e38b9de2d4a1acc7"

  url "https://github.com/roelvangils/phim/releases/download/v#{version}/Phim-#{version}.zip"
  name "Phim"
  desc "Minimalistic web viewer for macOS with vibrancy effects"
  homepage "https://phim.roel.app"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "Phim.app"
  binary "#{appdir}/Phim.app/Contents/MacOS/Phim", target: "phim"

  zap trash: [
    "~/Library/Preferences/com.phim.app.plist",
    "~/Library/Caches/com.phim.app",
    "~/Library/Application Support/com.phim.app",
  ]
end