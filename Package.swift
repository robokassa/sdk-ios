// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RobokassaSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "RobokassaSDK",
            targets: ["RobokassaSDK"]
        )
    ],
    targets: [
        .target(
            name: "RobokassaSDK",
            resources: [
                .process("AssetsResources/ic_robokassa_loader.png")
            ]
        ),
        .testTarget(
            name: "RobokassaSDKTests",
            dependencies: ["RobokassaSDK"]
        )
    ]
)
