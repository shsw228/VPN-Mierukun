// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LocalPackage",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VPNMierukunFeature",
            targets: ["VPNMierukunFeature"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.1"),
        .package(url: "https://github.com/cybozu/LicenseList.git", exact: "2.3.0")
    ],
    targets: [
        .target(
            name: "VPNMierukunSharedModels",
            path: "Sources/Shared/Models"
        ),
        .target(
            name: "VPNMierukunServices",
            dependencies: [
                "VPNMierukunSharedModels",
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources/Core/Services"
        ),
        .target(
            name: "VPNMierukunInfrastructure",
            dependencies: [
                "VPNMierukunSharedModels"
            ],
            path: "Sources/Core/Infrastructure"
        ),
        .target(
            name: "VPNMierukunStores",
            dependencies: [
                "VPNMierukunSharedModels",
                "VPNMierukunServices",
                "VPNMierukunInfrastructure"
            ],
            path: "Sources/Core/Stores"
        ),
        .target(
            name: "VPNMierukunMenuBarFeature",
            dependencies: [
                "VPNMierukunSharedModels",
                "VPNMierukunStores"
            ],
            path: "Sources/Features/MenuBar"
        ),
        .target(
            name: "VPNMierukunSettingsFeature",
            dependencies: [
                "VPNMierukunSharedModels",
                "VPNMierukunInfrastructure",
                "VPNMierukunStores",
                .product(name: "LicenseList", package: "LicenseList")
            ],
            path: "Sources/Features/Settings"
        ),
        .target(
            name: "VPNMierukunFeature",
            dependencies: [
                "VPNMierukunStores",
                "VPNMierukunMenuBarFeature",
                "VPNMierukunSettingsFeature"
            ],
            path: "Sources/AppEntry"
        )
    ]
)
