// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Listy",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "Listy",
            targets: ["Listy"]),
    ],
    dependencies: [
        .package(name: "FWCommonProtocols", url: "https://github.com/franklynw/FWCommonProtocols.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "Listy",
            dependencies: ["FWCommonProtocols"]),
        .testTarget(
            name: "ListyTests",
            dependencies: ["Listy"]),
    ]
)
