// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "JSON",
  dependencies: [
    .package(url: "../..", .branch("master")),
  ],
  targets: [
    .target(name: "JSON", dependencies: ["Diesel"]),
  ]
)
