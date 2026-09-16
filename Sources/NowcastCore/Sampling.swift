import Foundation

/// Limits expensive browser Automation reads while leaving cheap app mapping responsive.
public struct ActivitySamplingSchedule {
  public static let defaultBrowserInterval: TimeInterval = 3

  private let browserInterval: TimeInterval
  private var lastBrowserRead = Date.distantPast

  public init(browserInterval: TimeInterval = ActivitySamplingSchedule.defaultBrowserInterval) {
    self.browserInterval = max(0, browserInterval)
  }

  public mutating func shouldReadActivity(
    isBrowser: Bool,
    browserCollectionEnabled: Bool,
    forceBrowserRead: Bool = false,
    now: Date = Date()
  ) -> Bool {
    guard isBrowser && browserCollectionEnabled else { return true }
    let elapsed = now.timeIntervalSince(lastBrowserRead)
    guard forceBrowserRead || elapsed < 0 || elapsed >= browserInterval else { return false }
    lastBrowserRead = now
    return true
  }

  public mutating func reset() {
    lastBrowserRead = .distantPast
  }
}
