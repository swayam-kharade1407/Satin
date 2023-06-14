import Foundation
import PackagePlugin

@main struct CompilePipelinesPlugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        return [
            try .buildCommand(
                displayName: "Compile Shaders",
                executable: context.tool(named: "RenderPipelineBuilder").path,
                arguments: ["Hello", "World", "Bye"],
                environment: [:],
                inputFiles: [],
                outputFiles: []
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

func getShaders(file: Path) throws -> [Path] {
    var results = [Path]()
    var isDirectory: ObjCBool = false

    let fileString = file.string
    let fm = FileManager.default

    if fm.fileExists(atPath: fileString, isDirectory: &isDirectory) {
        if isDirectory.boolValue {
            let directoryFiles = try fm.contentsOfDirectory(atPath: fileString)
            for subPath in directoryFiles {
                results.append(contentsOf: try getShaders(file: file.appending(subpath: subPath)))
            }
        }
        else if file.lastComponent.contains("Shaders.metal") {
            results.append(file)
        }
    }

    return results
}

extension CompilePipelinesPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let outputPipelinesFolder = context.pluginWorkDirectory.appending("Pipelines")
        var commands = [Command]()

        let resources = target.inputFiles.filter { $0.type == .resource }
        if let assetFolderFile = resources.filter({ $0.path.stem == "Assets" }).first {

            let inputShaders = try getShaders(file: assetFolderFile.path)

            for inputShader in inputShaders {
                let inputShaderFolder = inputShader.removingLastComponent()
                let shaderLabel = inputShaderFolder.stem

                print("Label: \(shaderLabel)")
                print("Path: \(inputShader)")

                let outputShaderFolder = outputPipelinesFolder.appending(shaderLabel)

                let fm = FileManager.default
                if !fm.fileExists(atPath: outputShaderFolder.string) {
                    try fm.createDirectory(atPath: outputShaderFolder.string, withIntermediateDirectories: true)
                }

                let outputShader = outputShaderFolder.appending("\(shaderLabel).metal")
                let outputShaderParameters = outputShaderFolder.appending("\(shaderLabel).json")

                for outputFile in [outputShader, outputShaderParameters] {
                    if fm.fileExists(atPath: outputFile.string) {
                        try fm.removeItem(atPath: outputFile.string)
                    }
                }

                commands.append(
                    try .buildCommand(
                        displayName: "Building \(shaderLabel) Pipeline",
                        executable: context.tool(named: "RenderPipelineBuilder").path,
                        arguments: [shaderLabel, inputShader.string, outputShader.string, outputShaderParameters.string],
                        inputFiles: [inputShaderFolder, inputShader],
                        outputFiles: [outputShaderFolder]
                    )
                )
            }
        }

        return commands
    }
}

#endif
