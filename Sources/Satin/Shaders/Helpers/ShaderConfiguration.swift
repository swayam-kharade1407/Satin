//
//  ShaderConfiguration.swift
//
//
//  Created by Reza Ali on 6/14/23.
//

import Foundation
import Metal

public struct RenderingConfiguration: Equatable, Hashable {
    // Blending
    var blending = ShaderBlending()

    // Vertex Descriptor
    var vertexDescriptor = SatinVertexDescriptor()

    // Instancing
    var instancing: Bool = false

    // Lighting
    var lighting: Bool = false
    var lightCount: Int = 0

    // Shadows
    var castShadow: Bool = false
    var receiveShadow: Bool = false
    var shadowCount: Int = 0

    var defines: [String: NSObject] = [:]
    var constants: [String] = []

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blending)
        hasher.combine(vertexDescriptor)

        hasher.combine(instancing)
        hasher.combine(lighting)
        hasher.combine(lightCount)

        hasher.combine(castShadow)
        hasher.combine(receiveShadow)
        hasher.combine(shadowCount)

        hasher.combine(defines)
        hasher.combine(constants)
    }

    func getDefines() -> [String: NSObject] {
        var results = defines

#if os(iOS)
        results["MOBILE"] = NSString(string: "true")
#endif

        for attribute in VertexAttribute.allCases {
            switch vertexDescriptor.attributes[attribute.rawValue].format {
                case .invalid:
                    continue
                default:
                    results[attribute.shaderDefine] = NSString(string: "true")
            }
        }

        if instancing { results["INSTANCING"] = NSString(string: "true") }
        if lighting { results["LIGHTING"] = NSString(string: "true") }
        if lightCount > 0 { results["MAX_LIGHTS"] = NSNumber(value: lightCount) }
        if receiveShadow { results["HAS_SHADOWS"] = NSString(string: "true") }
        if shadowCount > 0 { results["SHADOW_COUNT"] = NSNumber(value: shadowCount) }

        return results
    }

    func getConstants() -> [String] {
        return constants
    }
}

public struct ShaderConfiguration: Equatable, Hashable {
    var context: Context?

    // Information
    var label: String

    var vertexFunctionName: String
    var fragmentFunctionName: String
    var shadowFunctionName: String

    // URLs
    var libraryURL: URL? // this is where we get the MTLLibrary from file and build from there
    var pipelineURL: URL? // this is where we get the pipeline source from file and build from there

    var rendering = RenderingConfiguration()

    public init(label: String = "",
                vertexFunctionName: String = "",
                fragmentFunctionName: String = "",
                shadowFunctionName: String = "",
                libraryURL: URL? = nil,
                pipelineURL: URL? = nil)
    {
        self.label = label
        self.vertexFunctionName = vertexFunctionName
        self.fragmentFunctionName = fragmentFunctionName
        self.shadowFunctionName = shadowFunctionName
        self.libraryURL = libraryURL
        self.pipelineURL = pipelineURL
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(label)

        hasher.combine(vertexFunctionName)
        hasher.combine(fragmentFunctionName)
        hasher.combine(shadowFunctionName)

        hasher.combine(libraryURL)
        hasher.combine(pipelineURL)

        hasher.combine(rendering)
    }

    func getLibraryConfiguration() -> ShaderLibraryConfiguration {
        return ShaderLibraryConfiguration(
            device: context?.device,
            label: label,
            libraryURL: libraryURL,
            pipelineURL: pipelineURL,
            vertexDescriptor: rendering.vertexDescriptor,
            instancing: rendering.instancing,
            lighting: rendering.lighting,
            castShadow: rendering.castShadow,
            receiveShadow: rendering.receiveShadow,
            shadowCount: rendering.shadowCount,
            defines: rendering.getDefines(),
            constants: rendering.getConstants()
        )
    }
}

extension ShaderConfiguration: CustomStringConvertible {
    public var description: String {
        var output = "\n"
        output += "\t Label: \(label)\n"
        output += "\t VertexName: \(vertexFunctionName)\n"
        output += "\t FragmentName: \(fragmentFunctionName)\n"
        output += "\t ShadowName: \(shadowFunctionName)\n"

        output += "\t libraryURL: \(libraryURL?.description ?? "nil")\n"
        output += "\t pipelineURL: \(pipelineURL?.description ?? "nil")\n"

        output += "\t blending: \(rendering.blending.type)\n"
        output += "\t vertexDescriptor: \(rendering.vertexDescriptor.description)\n"

        output += "\t instancing: \(rendering.instancing)\n"
        output += "\t lighting: \(rendering.lighting)\n"
        output += "\t lightCount: \(rendering.lightCount)\n"
        output += "\t castShadow: \(rendering.castShadow)\n"
        output += "\t receiveShadow: \(rendering.receiveShadow)\n"
        output += "\t shadowCount: \(rendering.shadowCount)\n"
        output += "\t defines: \(rendering.getDefines())\n"
        output += "\t constants: \(rendering.getConstants())\n"

        output += "\n"

        return output
    }
}
