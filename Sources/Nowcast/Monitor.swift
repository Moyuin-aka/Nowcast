import AppKit
import Combine
import ServiceManagement
import NowcastCore

@MainActor
final class Monitor: ObservableObject {
  @Published var config = Configuration()
  @Published var enabled = false
  @Published var activity: Activity?
  @Published var music: Music?
  @Published var connection = "尚未连接"
  @Published var warning: String?
  @Published var lastSuccess: Date?
  @Published var loginEnabled = SMAppService.mainApp.status == .enabled
  private let collector = Collector()
  private var stabilizer = ActivityStabilizer()
  private var timer: Timer?
  private var observations: [NSObjectProtocol] = []
  private var collecting = false
  private var suspended = false
  private var generation = 0
  private var lastMusicRead = Date.distantPast
  private var lastQueued = Date.distantPast
  private var lastSignature = ""
  private var pending: Presence?
  private var uploading = false
  private var secret = ""
  private let session = URLSession(configuration: .ephemeral, delegate: NoRedirect(), delegateQueue: nil)

  init() {
    do { config = try Storage.load() } catch { warning = "配置读取失败：\(error.localizedDescription)" }
    secret = Storage.secret()
    enabled = UserDefaults.standard.bool(forKey: "sharingEnabled") && warning == nil
    let center = NSWorkspace.shared.notificationCenter
    observations.append(center.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
      Task { @MainActor in self?.tick() }
    })
    for name in [NSWorkspace.willSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
      observations.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        Task { @MainActor in self?.setSuspended(true) }
      })
    }
    for name in [NSWorkspace.didWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
      observations.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        Task { @MainActor in self?.setSuspended(false) }
      })
    }
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.tick() }
    }
    tick()
  }

  func setSharing(_ value: Bool) {
    enabled = value; UserDefaults.standard.set(value, forKey: "sharingEnabled")
    generation += 1; stabilizer.clear(); activity = nil; music = nil
    lastSignature = ""; lastMusicRead = .distantPast
    if !value { enqueue(Presence(activity: nil, music: nil)); connection = "已暂停；正在清除公开状态" }
    else { tick() }
  }

  private func setSuspended(_ value: Bool) {
    suspended = value; generation += 1; stabilizer.clear(); activity = nil; music = nil
    lastSignature = ""; lastMusicRead = .distantPast
    if value && enabled { enqueue(Presence(activity: nil, music: nil)) }
    else { tick() }
  }

  func save(endpoint: String, newSecret: String, browser: Bool, music: Bool) {
    // Prevent a queued old destination update from racing configuration changes.
    guard !enabled && !uploading else { warning = "请先暂停共享，等待当前请求结束后再保存。"; return }
    var next = config
    next.endpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
    next.collectBrowser = browser; next.collectMusic = music
    do {
      try next.validate()
      if !newSecret.isEmpty { try Storage.saveSecret(newSecret); secret = newSecret }
      try Storage.save(next); config = next; warning = nil; connection = "配置已保存"
    } catch { warning = error.localizedDescription }
  }

  func reload() {
    guard !enabled && !uploading else { warning = "请先暂停共享，再重新载入规则。"; return }
    do { config = try Storage.load(); warning = nil; connection = "规则已载入" }
    catch { warning = error.localizedDescription }
  }

  func toggleLogin() {
    do {
      if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
      else { try SMAppService.mainApp.register() }
      loginEnabled = SMAppService.mainApp.status == .enabled
      if SMAppService.mainApp.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
    } catch { warning = "登录启动设置失败：\(error.localizedDescription)" }
  }

  func tick() {
    guard enabled && !suspended && !collecting else { return }
    let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
    // Opening this menu/settings must not replace the user's actual activity.
    guard bundleID != Bundle.main.bundleIdentifier else {
      if Date().timeIntervalSince(lastQueued) >= 60 { enqueue(Presence(activity: activity, music: music)) }
      return
    }
    collecting = true
    let token = generation
    let readMusic = Date().timeIntervalSince(lastMusicRead) >= 5
    var sampleConfig = config; sampleConfig.collectMusic = config.collectMusic && readMusic
    let musicRunning = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty == false
    Task {
      let sample = await collector.sample(bundleID: bundleID, config: sampleConfig, musicRunning: musicRunning)
      collecting = false
      guard token == generation && enabled && !suspended else { return }
      // Discard slow browser replies after the user has switched applications.
      guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleID else { return }
      activity = stabilizer.update(sample.activity)
      if readMusic { music = sample.music; lastMusicRead = Date() }
      if let message = sample.warning { warning = message }
      let payload = Presence(activity: activity, music: music)
      let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
      let signature = String(data: (try? encoder.encode(["activity": try? encoder.encode(activity), "music": try? encoder.encode(music)])) ?? Data(), encoding: .utf8) ?? ""
      if signature != lastSignature || Date().timeIntervalSince(lastQueued) >= 60 {
        lastSignature = signature; enqueue(payload)
      }
    }
  }

  private func enqueue(_ payload: Presence) {
    pending = payload; lastQueued = Date()
    guard !uploading else { return }
    uploading = true
    Task {
      while let next = pending {
        pending = nil
        guard let url = Configuration.endpointURL(config.endpoint), !secret.isEmpty else {
          connection = "本地预览 · 请设置 API 地址和密钥"; break
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"; request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(secret, forHTTPHeaderField: "x-now-playing-secret")
        request.httpBody = try? JSONEncoder().encode(next)
        do {
          let (_, response) = try await session.data(for: request)
          let status = (response as? HTTPURLResponse)?.statusCode ?? 0
          guard (200..<300).contains(status) else {
            connection = status == 401 ? "密钥不匹配（401）" : "上报失败（HTTP \(status)）"
            lastSignature = ""; break
          }
          lastSuccess = Date(); connection = enabled ? "已同步" : "已暂停 · 公开状态已清除"
        } catch {
          connection = "网络未连接 · 将自动重试"; lastSignature = ""; break
        }
      }
      uploading = false
      // Keep the newest pending update only; never replay a historical queue.
      if let latest = pending { pending = nil; enqueue(latest) }
    }
  }

  func clearBeforeQuit() async {
    setSharing(false)
    let deadline = Date().addingTimeInterval(2)
    while uploading && Date() < deadline { try? await Task.sleep(nanoseconds: 100_000_000) }
  }
}
