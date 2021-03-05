// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Listy",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "Listy",
            targets: ["Listy"]),
    ],
    dependencies: [
        .package(name: "BindableOffsetScrollView", url: "https://github.com/franklynw/BindableOffsetScrollView.git", .upToNextMajor(from: "1.0.0")),
        .package(name: "FWCommonProtocols", url: "https://github.com/franklynw/FWCommonProtocols.git", .upToNextMajor(from: "1.0.0")),
        .package(name: "ButtonConfig", url: "https://github.com/franklynw/ButtonConfig.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "Listy",
            dependencies: ["BindableOffsetScrollView", "FWCommonProtocols", "ButtonConfig"],
            resources: [.process("Resources")]),
        .testTarget(
            name: "ListyTests",
            dependencies: ["Listy"]),
    ]
)
