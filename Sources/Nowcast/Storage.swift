import Foundation
import Security
import NowcastCore

struct Storage {
  static var directory: URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Nowcast")
  }
  static var configURL: URL { directory.appendingPathComponent("config.json") }
  static func load() throws -> Configuration {
    if !FileManager.default.fileExists(atPath: configURL.path) {
      let c = Configuration(); try save(c); return c
    }
    let c = try JSONDecoder().decode(Configuration.self, from: Data(contentsOf: configURL))
    try c.validate(); return c
  }
  static func save(_ config: Configuration) throws {
    try config.validate()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try encoder.encode(config).write(to: configURL, options: .atomic)
  }
  private static let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "org.nowcast.presence",
    kSecAttrAccount as String: "api-secret",
  ]
  static func secret() -> String {
    var q = query; q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
      let data = result as? Data else { return "" }
    return String(data: data, encoding: .utf8) ?? ""
  }
  static func saveSecret(_ secret: String) throws {
    let data = Data(secret.utf8)
    let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
    if status == errSecItemNotFound {
      var q = query; q[kSecValueData as String] = data
      q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      let added = SecItemAdd(q as CFDictionary, nil)
      guard added == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(added)) }
    } else if status != errSecSuccess { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
  }
}

/// Never forward the write secret through an HTTP redirect.
final class NoRedirect: NSObject, URLSessionTaskDelegate {
  func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
}
