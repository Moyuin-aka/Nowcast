import XCTest
@testable import NowcastCore

final class PresenceTests: XCTestCase {
  func testDomainBoundaryAndSpecificity() {
    var c = Configuration()
    XCTAssertEqual(c.activity(bundleID: "browser", browserHost: "www.bilibili.com", isBrowser: true)?.source, "B站")
    XCTAssertEqual(c.activity(bundleID: "browser", browserHost: "evilbilibili.com", isBrowser: true)?.source, "浏览器")
    XCTAssertEqual(c.activity(bundleID: "browser", browserHost: "bilibili.com.evil.test", isBrowser: true)?.source, "浏览器")
    c.domains["live.bilibili.com"] = Rule("video", "看直播", "直播")
    XCTAssertEqual(c.activity(bundleID: "browser", browserHost: "live.bilibili.com", isBrowser: true)?.source, "直播")
  }
  func testUnknownAppsAndDisabledBrowserCollection() {
    var c = Configuration(); c.collectBrowser = false
    XCTAssertNil(c.activity(bundleID: "private.app"))
    XCTAssertEqual(c.activity(bundleID: "browser", browserHost: "claude.ai", isBrowser: true)?.source, "浏览器")
    XCTAssertEqual(c.activity(bundleID: "md.obsidian")?.kind, "writing")
  }
  func testDebounceAndStableStartTime() {
    var s = ActivityStabilizer()
    let t = Date(timeIntervalSince1970: 1_000)
    let a = Activity(kind: "writing", title: "写作", source: "Obsidian")
    XCTAssertNil(s.update(a, now: t))
    XCTAssertNil(s.update(a, now: t.addingTimeInterval(2)))
    let started = s.update(a, now: t.addingTimeInterval(3))?.startedAt
    XCTAssertNotNil(started)
    XCTAssertEqual(s.update(a, now: t.addingTimeInterval(60))?.startedAt, started)
    XCTAssertNotNil(s.update(nil, now: t.addingTimeInterval(61)))
    XCTAssertNil(s.update(nil, now: t.addingTimeInterval(64)))
  }
  func testBriefDetourPreservesOriginalStartTime() {
    var s = ActivityStabilizer()
    let t = Date(timeIntervalSince1970: 1_000)
    let coding = Activity(kind: "coding", title: "写代码", source: "VS Code")
    let browsing = Activity(kind: "browsing", title: "浏览网页", source: "浏览器")
    _ = s.update(coding, now: t)
    let original = s.update(coding, now: t.addingTimeInterval(3))
    XCTAssertEqual(s.update(browsing, now: t.addingTimeInterval(60)), original)
    XCTAssertEqual(s.update(browsing, now: t.addingTimeInterval(74)), original)
    XCTAssertEqual(s.update(coding, now: t.addingTimeInterval(74.5)), original)
    XCTAssertEqual(s.update(coding, now: t.addingTimeInterval(100)), original)
    // A later detour starts its own confirmation window.
    XCTAssertEqual(s.update(browsing, now: t.addingTimeInterval(110)), original)
    XCTAssertEqual(s.update(browsing, now: t.addingTimeInterval(124)), original)
    let switched = s.update(browsing, now: t.addingTimeInterval(125))
    XCTAssertEqual(switched?.source, "浏览器")
    XCTAssertEqual(switched?.startedAt, ISO8601DateFormatter().string(from: t.addingTimeInterval(110)))
    s.clear()
    XCTAssertNil(s.current)
    XCTAssertNil(s.update(coding, now: t.addingTimeInterval(130)))
    XCTAssertNotNil(s.update(coding, now: t.addingTimeInterval(133)))
  }
  func testEndpointValidation() {
    XCTAssertNotNil(Configuration.endpointURL("https://example.com/api/presence"))
    XCTAssertNotNil(Configuration.endpointURL("http://127.0.0.1:4321/api/presence"))
    for value in ["http://example.com", "https://user:secret@example.com", "file:///tmp/x", "https://example.com?secret=x"] {
      XCTAssertNil(Configuration.endpointURL(value))
    }
  }
  func testClearPayloadEncodesBothNulls() throws {
    let data = try JSONEncoder().encode(Presence(activity: nil, music: nil))
    let value = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    XCTAssertTrue(value["activity"] is NSNull)
    XCTAssertTrue(value["music"] is NSNull)
  }

  func testBrowserActivitySamplingUsesAdaptiveCadence() {
    var schedule = ActivitySamplingSchedule(browserInterval: 3)
    let start = Date(timeIntervalSince1970: 1_000)

    XCTAssertTrue(schedule.shouldReadActivity(
      isBrowser: true, browserCollectionEnabled: true, now: start))
    XCTAssertFalse(schedule.shouldReadActivity(
      isBrowser: true, browserCollectionEnabled: true, now: start.addingTimeInterval(2.99)))
    XCTAssertTrue(schedule.shouldReadActivity(
      isBrowser: true, browserCollectionEnabled: true, now: start.addingTimeInterval(3)))
    XCTAssertTrue(schedule.shouldReadActivity(
      isBrowser: true, browserCollectionEnabled: true, forceBrowserRead: true,
      now: start.addingTimeInterval(3.1)))
    XCTAssertFalse(schedule.shouldReadActivity(
      isBrowser: true, browserCollectionEnabled: true, now: start.addingTimeInterval(6)))
    XCTAssertTrue(schedule.shouldReadActivity(
      isBrowser: false, browserCollectionEnabled: true, now: start.addingTimeInterval(6)))
    XCTAssertTrue(schedule.shouldReadActivity(
      isBrowser: true, browserCollectionEnabled: false, now: start.addingTimeInterval(6)))

    schedule.reset()
    XCTAssertTrue(schedule.shouldReadActivity(
      isBrowser: true, browserCollectionEnabled: true, now: start.addingTimeInterval(6)))
  }
}
