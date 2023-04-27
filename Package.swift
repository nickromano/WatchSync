// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "WatchSync",
  platforms: [
    .iOS(.v13),
    .watchOS(.v4),
  ],
  products: [
    .library(name: "WatchSync", targets: ["WatchSync"]),
  ],
  dependencies: [
    .package(url: "https://github.com/1024jp/GzipSwift", from: "5.0.0"),
  ],
  targets: [
    .target(
      name: "WatchSync",
      dependencies: [
        .product(name: "Gzip", package: "GzipSwift"),
      ]
    ),
  ]
)
