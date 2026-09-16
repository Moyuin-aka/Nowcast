import Combine
import Sparkle
import SwiftUI

@MainActor
final class UpdateController {
  private let controller = SPUStandardUpdaterController(
    startingUpdater: true,
    updaterDelegate: nil,
    userDriverDelegate: nil
  )

  var canCheckForUpdates: Bool { controller.updater.canCheckForUpdates }
  var currentVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "开发版"
  }

  func checkForUpdates() {
    controller.updater.checkForUpdates()
  }

  fileprivate var updater: SPUUpdater { controller.updater }
}

@MainActor
private final class UpdateAvailability: ObservableObject {
  @Published var canCheckForUpdates = false

  init(updater: SPUUpdater) {
    updater.publisher(for: \.canCheckForUpdates)
      .assign(to: &$canCheckForUpdates)
  }
}

@MainActor
struct CheckForUpdatesButton: View {
  private let updates: UpdateController
  @StateObject private var availability: UpdateAvailability

  init(updates: UpdateController) {
    self.updates = updates
    _availability = StateObject(wrappedValue: UpdateAvailability(updater: updates.updater))
  }

  var body: some View {
    Button("检查更新…") { updates.checkForUpdates() }
      .disabled(!availability.canCheckForUpdates)
  }
}
