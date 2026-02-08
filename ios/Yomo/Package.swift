// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Yomo",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Yomo",
            targets: ["Yomo"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.20.0"),
        .package(url: "https://github.com/RevenueCat/purchases-ios", from: "4.37.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "Yomo",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ]
        ),
        .testTarget(
            name: "YomoTests",
            dependencies: ["Yomo"]
        )
    ]
)
