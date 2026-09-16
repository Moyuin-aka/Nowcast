import AppKit
import NowcastCore

struct Sample {
  var activity: Activity?
  var music: Music?
  var warning: String?
}

/// Scripts run off the UI thread, with a deadline. Never logs URLs or titles.
actor Collector {
  static let browsers: [String: String] = [
    "com.apple.Safari": "Safari",
    "com.google.Chrome": "Chrome",
    "com.microsoft.edgemac": "Edge",
    "company.thebrowser.Browser": "Arc",
    "com.brave.Browser": "Brave",
  ]

  private func script(_ source: String) -> String? {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-l", "JavaScript", "-e", source]
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    do { try process.run() } catch { return nil }
    let deadline = Date().addingTimeInterval(4)
    while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.05) }
    if process.isRunning { process.terminate(); return nil }
    guard process.terminationStatus == 0 else { return nil }
    let data = output.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func sample(
    bundleID: String,
    config: Configuration,
    musicRunning: Bool,
    readActivity: Bool,
    readMusic: Bool
  ) -> Sample {
    var warning: String?
    var host: String?
    let browser = Self.browsers[bundleID] != nil
    if readActivity && browser && config.collectBrowser {
      // bundleID comes exclusively from the fixed allowlist above.
      let tab = bundleID == "com.apple.Safari" ? "currentTab()" : "activeTab()"
      let result = script("""
        const app = Application('\(bundleID)');
        let result = {host: null};
        if (app.running() && app.windows.length > 0) {
          const raw = app.windows[0].\(tab).url();
          const match = new RegExp('^https?://([^/:?#]+)', 'i').exec(raw || '');
          if (match && match[1].indexOf('@') === -1) result.host = match[1].toLowerCase().slice(0, 253);
        }
        JSON.stringify(result);
        """)
      if let result, let data = result.data(using: .utf8),
        let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        host = value["host"] as? String
      } else { warning = "浏览器读取失败：请检查系统设置 → 隐私与安全性 → 自动化。" }
    }
    let activity = readActivity
      ? config.activity(bundleID: bundleID, browserHost: host, isBrowser: browser)
      : nil
    var music: Music?
    if readMusic && config.collectMusic && musicRunning {
      let result = script("""
        const app = Application('com.apple.Music');
        let result = null;
        if (app.running() && app.playerState() === 'playing') {
          const t = app.currentTrack();
          result = {title: String(t.name() || '').slice(0, 200),
            artist: String(t.artist() || '').slice(0, 200), album: String(t.album() || '').slice(0, 200)};
        }
        JSON.stringify(result);
        """)
      if let result, let data = result.data(using: .utf8) {
        if let value = try? JSONSerialization.jsonObject(with: data) as? [String: String],
          let title = value["title"], !title.isEmpty {
          music = Music(title: title, artist: value["artist"] ?? "", album: value["album"] ?? "")
        }
      } else { warning = "Music 读取失败：请检查自动化权限；暂停共享后可重新开启。" }
    }
    return Sample(activity: activity, music: music, warning: warning)
  }
}
