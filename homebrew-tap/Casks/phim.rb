cask "phim" do
  version "0.3.0"
  sha256 "1b9a10b3d9e1fab1a89be7580e27af23b22e349baf9473ec9428a68003db61d6"

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

  postflight do
    # Remove quarantine attribute to bypass Gatekeeper warning for unsigned app
    # This is safe - Phim is open source and you can verify the code yourself
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Phim.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.phim.app.plist",
    "~/Library/Caches/com.phim.app",
    "~/Library/Application Support/com.phim.app",
  ]
end