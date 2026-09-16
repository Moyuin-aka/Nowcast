// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Nowcast",
  platforms: [.macOS(.v13)],
  products: [.executable(name: "Nowcast", targets: ["Nowcast"])],
  dependencies: [
    .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
  ],
  targets: [
    .target(name: "NowcastCore"),
    .executableTarget(
      name: "Nowcast",
      dependencies: ["NowcastCore", .product(name: "Sparkle", package: "Sparkle")],
      linkerSettings: [
        .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
      ]
    ),
    .testTarget(name: "NowcastCoreTests", dependencies: ["NowcastCore"]),
  ]
)
