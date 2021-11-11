// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZConnectVerificaC19SDK",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ZConnectVerificaC19SDK",
            targets: ["ZConnectVerificaC19SDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            name: "SwiftyJSON",
            url: "https://github.com/SwiftyJSON/SwiftyJSON",
            from: "5.0.1"),
        .package(
            name: "Alamofire",
            url: "https://github.com/Alamofire/Alamofire",
            from: "5.4.3"),
        .package(
            name: "SwiftDGC",
            url: "https://github.com/eu-digital-green-certificates/dgca-app-core-ios",
            .branch("main"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ZConnectVerificaC19SDK",
            dependencies: [
                "SwiftyJSON",
                "Alamofire",
                "SwiftDGC"
            ],
            resources: [.copy("Res")]
        )
    ]
)