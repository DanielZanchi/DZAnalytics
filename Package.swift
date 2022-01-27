// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DZDataAnalytics",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DZDataAnalytics",
            targets: ["DZDataAnalytics"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk.git", from: "8.0.0"),
        .package(name: "SwiftyStoreKit", url: "https://github.com/bizz84/SwiftyStoreKit.git", from: "0.16.3"),
        .package(name: "SwiftKeychainWrapper", url: "https://github.com/jrendel/SwiftKeychainWrapper", from: "4.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DZDataAnalytics",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "Firebase"),
                .product(name: "FirebaseAuth", package: "Firebase"),
                .product(name: "SwiftyStoreKit", package: "SwiftyStoreKit"),
                .product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper")
            ]),
    ]
)
