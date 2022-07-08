// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DZDataAnalytics",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "DZDataAnalytics",
            targets: ["DZDataAnalytics"]),
    ],
    dependencies: [
        .package(name: "SwiftyStoreKit", url: "https://github.com/bizz84/SwiftyStoreKit.git", from: "0.16.4"),
        .package(name: "SwiftKeychainWrapper", url: "https://github.com/jrendel/SwiftKeychainWrapper", from: "4.0.1"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "9.2.0")
    ],
    targets: [
        .target(
            name: "DZDataAnalytics",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "SwiftyStoreKit", package: "SwiftyStoreKit"),
                .product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper")
            ]),
    ]
)
