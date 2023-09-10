//
//  RenderingConfiguration.swift
//
//
//  Created by Reza Ali on 6/15/23.
//

import Foundation

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

    var defines: [ShaderDefine] = []
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

        if !defines.isEmpty { hasher.combine(defines) }
        if !constants.isEmpty { hasher.combine(constants) }
    }

    func getDefines() -> [ShaderDefine] {
        var results = defines

#if os(iOS)
        results.append(ShaderDefine(key: "MOBILE", value: NSString(string: "true")))
#endif

#if DEBUG
        results.append(ShaderDefine(key: "DEBUG", value: NSString(string: "true")))
#endif

        for attribute in VertexAttributeIndex.allCases {
            switch vertexDescriptor.attributes[attribute.rawValue].format {
                case .invalid:
                    continue
                default:
                    results.append(ShaderDefine(key: attribute.shaderDefine, value: NSString(string: "true")))
            }
        }

        if instancing { results.append(ShaderDefine(key: "INSTANCING", value: NSString(string: "true"))) }
        if lighting { results.append(ShaderDefine(key: "LIGHTING", value: NSString(string: "true"))) }
        if lightCount > 0 { results.append(ShaderDefine(key: "MAX_LIGHTS", value: NSNumber(value: lightCount))) }
        if receiveShadow { results.append(ShaderDefine(key: "HAS_SHADOWS", value: NSString(string: "true"))) }
        if shadowCount > 0 { results.append(ShaderDefine(key: "SHADOW_COUNT", value: NSNumber(value: shadowCount))) }

        return results
    }

    func getConstants() -> [String] {
        return constants
    }
}

extension RenderingConfiguration: CustomStringConvertible {
    public var description: String {
        var output = "RenderingConfiguration: \n"

        output += "\t\t \(blending.description)"

        output += "\t\t instancing: \(instancing)\n"
        output += "\t\t lighting: \(lighting)\n"
        output += "\t\t lightCount: \(lightCount)\n"
        output += "\t\t castShadow: \(castShadow)\n"
        output += "\t\t receiveShadow: \(receiveShadow)\n"
        output += "\t\t shadowCount: \(shadowCount)\n"

        if !defines.isEmpty {
            output += "\t\t defines:\n"
            for (index, define) in defines.enumerated() {
                output += "\t\t\t \(index): \(define.description)"
            }
        }

        if !constants.isEmpty {
            output += "\t\t constants:\n"
            for (index, constant) in constants.enumerated() {
                output += "\t\t\t \(index): \(constant)\n"
            }
        }

        return output
    }
}
