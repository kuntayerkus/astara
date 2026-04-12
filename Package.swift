// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Astara",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Astara", targets: ["Astara"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.17.0"
        ),
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess",
            from: "4.2.2"
        ),
        .package(
            url: "https://github.com/airbnb/lottie-ios",
            from: "4.4.0"
        ),
    ],
    targets: [
        .target(
            name: "Astara",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "Lottie", package: "lottie-ios"),
            ],
            path: "Astara"
        )
    ]
)
