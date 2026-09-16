import AppKit
import SwiftUI
import Combine

@main
struct NowcastApp {
  @MainActor static func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(delegate) { app.run() }
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private var statusItem: NSStatusItem!
  private var window: NSWindow?
  private var model: Monitor!
  private let updates = UpdateController()
  private var subscription: AnyCancellable?

  func applicationDidFinishLaunching(_ notification: Notification) {
    updates.start()
    model = Monitor()
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(systemSymbolName: "dot.radiowaves.left.and.right", accessibilityDescription: "Nowcast")
    let menu = NSMenu(); menu.delegate = self; statusItem.menu = menu
    subscription = model.$enabled.sink { [weak self] enabled in
      self?.statusItem.button?.appearsDisabled = !enabled
    }
    if !UserDefaults.standard.bool(forKey: "onboarded") {
      showSettings(); UserDefaults.standard.set(true, forKey: "onboarded")
    }
  }
  func menuWillOpen(_ menu: NSMenu) {
    menu.removeAllItems()
    let heading = NSMenuItem(title: "NOWCAST · 此刻", action: nil, keyEquivalent: "")
    heading.isEnabled = false; menu.addItem(heading)
    menu.addItem(withTitle: model.enabled ? (model.activity?.title ?? "没有公开的前台活动") : "已暂停共享", action: nil, keyEquivalent: "")
    if let music = model.music { menu.addItem(withTitle: "♫ \(music.title) — \(music.artist)", action: nil, keyEquivalent: "") }
    menu.addItem(withTitle: model.connection, action: nil, keyEquivalent: "")
    menu.addItem(.separator())
    item(menu, model.enabled ? "暂停共享" : "开始共享", #selector(toggleSharing))
    item(menu, "状态与设置…", #selector(showSettings), ",")
    item(menu, "登录时启动", #selector(toggleLogin)).state = model.loginEnabled ? .on : .off
    menu.addItem(.separator())
    item(menu, "检查更新…", #selector(checkForUpdates)).isEnabled = updates.canCheckForUpdates
    menu.addItem(.separator())
    item(menu, "退出 Nowcast", #selector(quit), "q")
  }
  @discardableResult private func item(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String = "") -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: key); item.target = self; menu.addItem(item); return item
  }
  @objc private func toggleSharing() { model.setSharing(!model.enabled) }
  @objc private func toggleLogin() { model.toggleLogin() }
  @objc private func checkForUpdates() { updates.checkForUpdates() }
  @objc private func quit() { Task { await model.clearBeforeQuit(); NSApp.terminate(nil) } }
  @objc private func showSettings() {
    if window == nil {
      let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 670),
        styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
      w.title = "Nowcast"; w.isReleasedWhenClosed = false
      w.contentView = NSHostingView(rootView: SettingsView(model: model, updates: updates))
      w.center(); window = w
    }
    NSApp.activate(ignoringOtherApps: true); window?.makeKeyAndOrderFront(nil)
  }
}

struct SettingsView: View {
  @ObservedObject var model: Monitor
  let updates: UpdateController
  @State private var endpoint = ""
  @State private var secret = ""
  @State private var browser = true
  @State private var music = true
  private let accent = Color(red: 0.16, green: 0.48, blue: 0.39)

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 5) {
            Text("NOWCAST").font(.system(size: 11, weight: .semibold, design: .monospaced)).tracking(3).foregroundStyle(accent)
            Text("把此刻，轻轻广播。") .font(.system(size: 25, weight: .medium, design: .serif))
          }
          Spacer()
          Image(systemName: "dot.radiowaves.left.and.right").font(.system(size: 27)).foregroundStyle(accent)
        }
        VStack(alignment: .leading, spacing: 10) {
          Label(model.enabled ? "正在共享" : "仅你可见 · 已暂停", systemImage: model.enabled ? "circle.fill" : "pause.circle")
            .font(.caption).foregroundStyle(accent)
          Text(model.activity?.title ?? "等待下一件有趣的事") .font(.title2.weight(.medium))
          if let source = model.activity?.source { Text(source).font(.caption).foregroundStyle(.secondary) }
          if let track = model.music {
            Divider()
            Label("\(track.title) · \(track.artist)", systemImage: "music.note").font(.callout).lineLimit(2)
          }
          HStack {
            Text(model.connection).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button(model.enabled ? "暂停共享" : "开始共享") { model.setSharing(!model.enabled) }.tint(accent)
          }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

        VStack(alignment: .leading, spacing: 10) {
          Text("连接你的网站").font(.headline)
          TextField("https://example.com/api/presence", text: $endpoint)
            .textFieldStyle(.roundedBorder).accessibilityLabel("API 地址")
          SecureField("写入密钥（留空保留已有密钥）", text: $secret).textFieldStyle(.roundedBorder)
          Text("密钥保存在 macOS 钥匙串。未配置 API 时，可以先在本机预览。")
            .font(.caption).foregroundStyle(.secondary)
          Toggle("识别浏览器中的网站", isOn: $browser)
          Toggle("显示后台 Apple Music", isOn: $music)
          HStack {
            Button("保存设置") {
              model.save(endpoint: endpoint, newSecret: secret, browser: browser, music: music)
              secret = ""
            }.disabled(model.enabled)
            Text("修改设置前请先暂停共享").font(.caption).foregroundStyle(.secondary)
          }
        }
        if let warning = model.warning {
          Text(warning).font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
        }
        Divider()
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("你的应用，你的表达").font(.headline)
            Spacer()
            Button("编辑规则") { NSWorkspace.shared.open(Storage.configURL) }
            Button("重新载入") {
              model.reload(); endpoint = model.config.endpoint
              browser = model.config.collectBrowser; music = model.config.collectMusic
            }.disabled(model.enabled)
          }
          Text("VS Code → 写代码　Terminal → Vibe Coding\nObsidian → 写作　浏览器 → 按网站分类")
            .font(.caption).foregroundStyle(.secondary).lineSpacing(4)
          Text("只上传规则文案和播放中的歌曲。不上传窗口标题、网页地址、笔记内容或终端命令。Mac 休眠后，公开状态会清除或在 3 分钟内过期。")
            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        Divider()
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Nowcast \(updates.currentVersion)").font(.headline)
            Text("从 GitHub Releases 安全检查并安装新版本。")
              .font(.caption).foregroundStyle(.secondary)
          }
          Spacer()
          CheckForUpdatesButton(updates: updates)
        }
      }.padding(28)
    }
    .frame(width: 480, height: 670)
    .onAppear {
      endpoint = model.config.endpoint; browser = model.config.collectBrowser; music = model.config.collectMusic
    }
  }
}
