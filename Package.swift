// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DZDataAnalytics",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "DZDataAnalytics",
            targets: ["DZDataAnalytics"]),
    ],
    dependencies: [
        .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk.git", .exactItem("8.13.0")),
        .package(name: "SwiftyStoreKit", url: "https://github.com/bizz84/SwiftyStoreKit.git", from: "0.16.4"),
        .package(name: "SwiftKeychainWrapper", url: "https://github.com/jrendel/SwiftKeychainWrapper", from: "4.0.1")
    ],
    targets: [
        .target(
            name: "DZDataAnalytics",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "Firebase"),
                .product(name: "FirebaseAuth", package: "Firebase"),
                .product(name: "FirebaseStorage", package: "Firebase"),
                .product(name: "SwiftyStoreKit", package: "SwiftyStoreKit"),
                .product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper")
            ]),
    ]
)
