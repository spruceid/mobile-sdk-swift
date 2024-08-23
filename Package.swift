// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpruceIDWalletSdk",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SpruceIDWalletSdk",
            targets: ["SpruceIDWalletSdk"])
    ],
    dependencies: [
        // .package(url: "https://github.com/spruceid/wallet-sdk-rs.git", from: "0.0.25"),
        .package(path: "../wallet-sdk-rs"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "SpruceIDWalletSdk",
            dependencies: [
                .product(name: "SpruceIDMobileSdkRs", package: "wallet-sdk-rs"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ]
        ),
        .testTarget(
            name: "SpruceIDWalletSdkTests",
            dependencies: ["SpruceIDWalletSdk"])
    ]
)
