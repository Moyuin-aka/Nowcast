// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Nowcast",
  platforms: [.macOS(.v13)],
  products: [.executable(name: "Nowcast", targets: ["Nowcast"])],
  targets: [
    .target(name: "NowcastCore"),
    .executableTarget(name: "Nowcast", dependencies: ["NowcastCore"]),
    .testTarget(name: "NowcastCoreTests", dependencies: ["NowcastCore"]),
  ]
)
