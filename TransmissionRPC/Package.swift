// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "TransmissionRPC",
  platforms: [
    .macOS(.v12),
    .iOS(.v15),
  ],
  products: [
    .library(name: "TransmissionRPC", targets: ["TransmissionRPC"])
  ],
  targets: [
    .target(
      name: "TransmissionRPC",
      dependencies: []
    ),
    .testTarget(
      name: "TransmissionRPCTests",
      dependencies: ["TransmissionRPC"]
    ),
  ]
)

