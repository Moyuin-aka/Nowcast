import Foundation

public struct Activity: Codable, Equatable {
  public var kind: String
  public var title: String
  public var source: String
  public var startedAt: String?
  public init(kind: String, title: String, source: String, startedAt: String? = nil) {
    self.kind = kind; self.title = title; self.source = source; self.startedAt = startedAt
  }
}

public struct Music: Codable, Equatable {
  public var state = "playing"
  public var title: String
  public var artist: String
  public var album: String
  public init(title: String, artist: String, album: String) {
    self.title = title; self.artist = artist; self.album = album
  }
}

public struct Presence: Codable, Equatable {
  public var version = 1
  public var activity: Activity?
  public var music: Music?
  public var observedAt: String
  public init(activity: Activity?, music: Music?, now: Date = Date()) {
    self.activity = activity; self.music = music
    observedAt = ISO8601DateFormatter().string(from: now)
  }
  // Explicit nulls make clearing a channel unambiguous across receivers.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(version, forKey: .version)
    try c.encode(activity, forKey: .activity)
    try c.encode(music, forKey: .music)
    try c.encode(observedAt, forKey: .observedAt)
  }
}

public struct Rule: Codable, Equatable {
  public var kind: String
  public var title: String
  public var source: String
  public init(_ kind: String, _ title: String, _ source: String) {
    self.kind = kind; self.title = title; self.source = source
  }
  public var activity: Activity { Activity(kind: kind, title: title, source: source) }
}

public struct Configuration: Codable {
  public var endpoint = ""
  public var collectBrowser = true
  public var collectMusic = true
  public var apps: [String: Rule] = [
    "com.microsoft.VSCode": Rule("coding", "写代码", "VS Code"),
    "com.microsoft.VSCodeInsiders": Rule("coding", "写代码", "VS Code Insiders"),
    "com.apple.Terminal": Rule("vibe", "Vibe Coding", "Terminal"),
    "com.googlecode.iterm2": Rule("vibe", "Vibe Coding", "iTerm2"),
    "com.mitchellh.ghostty": Rule("vibe", "Vibe Coding", "Ghostty"),
    "dev.warp.Warp-Stable": Rule("vibe", "Vibe Coding", "Warp"),
    "md.obsidian": Rule("writing", "写作", "Obsidian"),
    "com.todesktop.230313mzl4w4u92": Rule("vibe", "Vibe Coding", "Cursor"),
    "com.anthropic.claudefordesktop": Rule("ai", "与 AI 聊天", "Claude"),
    "com.openai.chat": Rule("ai", "与 AI 聊天", "ChatGPT"),
  ]
  public var domains: [String: Rule] = [
    "bilibili.com": Rule("browsing", "逛 B站", "B站"),
    "xiaohongshu.com": Rule("browsing", "刷小红书", "小红书"),
    "chatgpt.com": Rule("ai", "与 AI 聊天", "ChatGPT"),
    "claude.ai": Rule("ai", "与 AI 聊天", "Claude"),
    "gemini.google.com": Rule("ai", "与 AI 聊天", "Gemini"),
    "chat.deepseek.com": Rule("ai", "与 AI 聊天", "DeepSeek"),
    "doubao.com": Rule("ai", "与 AI 聊天", "豆包"),
    "github.com": Rule("browsing", "逛 GitHub", "GitHub"),
  ]
  public init() {}
  public static let kinds: Set<String> = ["coding", "vibe", "writing", "ai", "browsing", "reading", "video", "game", "other"]
  public func validate() throws {
    if !endpoint.isEmpty && Self.endpointURL(endpoint) == nil { throw ConfigError.invalidEndpoint }
    for (key, rule) in apps.merging(domains, uniquingKeysWith: { a, _ in a }) {
      guard !key.isEmpty, Self.kinds.contains(rule.kind), !rule.title.isEmpty,
        rule.title.count <= 120, !rule.source.isEmpty, rule.source.count <= 80 else {
        throw ConfigError.invalidRule(key)
      }
    }
  }
  public static func endpointURL(_ value: String) -> URL? {
    guard let u = URL(string: value), let host = u.host, u.user == nil, u.password == nil,
      u.fragment == nil, u.query == nil,
      u.scheme == "https" || (u.scheme == "http" && ["localhost", "127.0.0.1", "[::1]"].contains(host)) else { return nil }
    return u
  }
  public func activity(bundleID: String, browserHost: String? = nil, isBrowser: Bool = false) -> Activity? {
    if isBrowser {
      if collectBrowser, let host = browserHost?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) {
        for domain in domains.keys.sorted(by: { $0.count > $1.count }) {
          if host == domain || host.hasSuffix("." + domain) { return domains[domain]?.activity }
        }
      }
      return Activity(kind: "browsing", title: "浏览网页", source: "浏览器")
    }
    return apps[bundleID]?.activity
  }
}

public enum ConfigError: LocalizedError {
  case invalidEndpoint, invalidRule(String)
  public var errorDescription: String? {
    switch self {
    case .invalidEndpoint: return "API 地址须为 HTTPS（本机调试允许 HTTP），且不能含账号、查询参数或片段。"
    case .invalidRule(let key): return "规则无效：\(key)。检查 kind、title 和 source。"
    }
  }
}

/// Only publish a new foreground after it remains stable for three seconds.
public struct ActivityStabilizer {
  private var candidate: Activity?
  private var candidateSince = Date.distantPast
  public private(set) var current: Activity?
  public init() {}
  public mutating func update(_ activity: Activity?, now: Date = Date()) -> Activity? {
    var clean = activity; clean?.startedAt = nil
    if clean != candidate { candidate = clean; candidateSince = now }
    var comparable = current; comparable?.startedAt = nil
    if candidate != comparable && now.timeIntervalSince(candidateSince) >= 3 {
      current = candidate
      current?.startedAt = ISO8601DateFormatter().string(from: candidateSince)
    }
    return current
  }
  public mutating func clear() { candidate = nil; current = nil; candidateSince = .distantPast }
}
