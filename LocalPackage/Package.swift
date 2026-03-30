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
    targets: [
        .target(
            name: "VPNMierukunSharedModels",
            path: "Sources/Shared/Models"
        ),
        .target(
            name: "VPNMierukunServices",
            dependencies: [
                "VPNMierukunSharedModels"
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
                "VPNMierukunStores"
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
