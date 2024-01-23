// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Satin",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .visionOS(.v1)],
    products: [
        .library(
            name: "SatinCore",
            targets: ["SatinCore"]
        ),
        .library(
            name: "Satin",
            targets: ["Satin"]
        ),
        .executable(
            name: "RenderPipelineBuilder",
            targets: ["RenderPipelineBuilder"]
        ),
        .plugin(
            name: "CompilePipelines",
            targets: ["CompilePipelines"]
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
        ),
        .executableTarget(
            name: "RenderPipelineBuilder",
            dependencies: ["Satin"]
        ),
        .plugin(
            name: "CompilePipelines",
            capability: .buildTool(),
            dependencies: ["RenderPipelineBuilder"]
        )
    ],
    swiftLanguageVersions: [.v5],
    cxxLanguageStandard: .cxx17
)
