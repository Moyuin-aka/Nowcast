import Combine
import Sparkle
import SwiftUI

@MainActor
final class UpdateController: ObservableObject {
  @Published private(set) var canCheckForUpdates = false
  private let controller: SPUStandardUpdaterController?

  init(bundle: Bundle = .main) {
    guard bundle.bundleURL.pathExtension == "app",
      let feedURL = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
      let publicKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
      !feedURL.isEmpty, !publicKey.isEmpty else {
      controller = nil
      return
    }
    let controller = SPUStandardUpdaterController(
      startingUpdater: false,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )
    self.controller = controller
    canCheckForUpdates = controller.updater.canCheckForUpdates
    controller.updater.publisher(for: \.canCheckForUpdates, options: [.new])
      .assign(to: &$canCheckForUpdates)
  }

  var currentVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "开发版"
  }

  func start() {
    controller?.startUpdater()
  }

  func checkForUpdates() {
    controller?.updater.checkForUpdates()
  }
}

@MainActor
struct CheckForUpdatesButton: View {
  @ObservedObject var updates: UpdateController

  var body: some View {
    Button("检查更新…") { updates.checkForUpdates() }
      .disabled(!updates.canCheckForUpdates)
  }
}
