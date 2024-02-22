// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Satin",
    platforms: [.macOS(.v11), .iOS(.v17), .tvOS(.v17), .visionOS(.v1)],
    products: [
        .library(
            name: "SatinCore",
            targets: ["SatinCore"]
        ),
        .library(
            name: "Satin",
            targets: ["Satin"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SatinCore",
            path: "Sources/SatinCore",
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("include")],
            cxxSettings: [.headerSearchPath("include")]
        ),
        .testTarget(
            name: "SatinCoreTests",
            dependencies: ["SatinCore"]
        ),
        .target(
            name: "Satin",
            dependencies: ["SatinCore"],
            path: "Sources/Satin",
            resources: [.copy("Pipelines")]
        ),
        .testTarget(
            name: "SatinTests",
            dependencies: ["Satin"]
        )
    ],
    swiftLanguageVersions: [.v5],
    cxxLanguageStandard: .cxx17
)
