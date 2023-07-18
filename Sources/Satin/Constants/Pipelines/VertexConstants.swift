//
//  VertexFunctionConstants.swift
//
//
//  Created by Reza Ali on 3/17/23.
//

import Foundation
import ModelIO

public enum VertexBufferIndex: Int, CaseIterable, Codable {
    case Vertices = 0

    case VertexUniforms = 1
    case InstanceMatrixUniforms = 2
    case MaterialUniforms = 3
    case ShadowMatrices = 4

    case Position = 5
    case Normal = 6
    case Texcoord = 7
    case Tangent = 8
    case Bitangent = 9
    case Color = 10
    case Anisotropy = 11
    case Binormal = 12
    case Occlusion = 13
    case EdgeCrease = 14
    case JointIndices = 15
    case JointWeights = 16
    case ShadingBasisU = 17
    case ShadingBasisV = 18
    case SubdivisionStencil = 19

    case Custom0 = 20
    case Custom1 = 21
    case Custom2 = 22
    case Custom3 = 23
    case Custom4 = 24
    case Custom5 = 25
    case Custom6 = 26
    case Custom7 = 27
    case Custom8 = 28
    case Custom9 = 29
    case Custom10 = 30
    case Custom11 = 31

    public var label: String {
        String(describing: self)
    }
}

public enum VertexAttributeIndex: Int, CaseIterable, Codable {
    case Position = 0
    case Normal = 1
    case Texcoord = 2
    case Tangent = 3
    case Bitangent = 4
    case Color = 5
    case Anisotropy = 6
    case Binormal = 7
    case Occlusion = 8
    case EdgeCrease = 9
    case JointIndices = 10
    case JointWeights = 11
    case ShadingBasisU = 12
    case ShadingBasisV = 13
    case SubdivisionStencil = 14
    case Custom0 = 15
    case Custom1 = 16
    case Custom2 = 17
    case Custom3 = 18
    case Custom4 = 19
    case Custom5 = 20
    case Custom6 = 21
    case Custom7 = 22
    case Custom8 = 23
    case Custom9 = 24
    case Custom10 = 25
    case Custom11 = 26

    public var description: String {
        String(describing: self).titleCase
    }

    public var mdl: String {
        switch self {
            case .Position:
                return MDLVertexAttributePosition
            case .Normal:
                return MDLVertexAttributeNormal
            case .Texcoord:
                return MDLVertexAttributeTextureCoordinate
            case .Tangent:
                return MDLVertexAttributeTangent
            case .Bitangent:
                return MDLVertexAttributeBitangent
            case .Color:
                return MDLVertexAttributeColor
            case .Anisotropy:
                return MDLVertexAttributeAnisotropy
            case .Binormal:
                return MDLVertexAttributeBinormal
            case .Occlusion:
                return MDLVertexAttributeOcclusionValue
            case .EdgeCrease:
                return MDLVertexAttributeEdgeCrease
            case .JointIndices:
                return MDLVertexAttributeJointIndices
            case .JointWeights:
                return MDLVertexAttributeJointWeights
            case .ShadingBasisU:
                return MDLVertexAttributeShadingBasisU
            case .ShadingBasisV:
                return MDLVertexAttributeShadingBasisV
            case .SubdivisionStencil:
                return MDLVertexAttributeSubdivisionStencil
            case .Custom0:
                return "Invalid"
            case .Custom1:
                return "Invalid"
            case .Custom2:
                return "Invalid"
            case .Custom3:
                return "Invalid"
            case .Custom4:
                return "Invalid"
            case .Custom5:
                return "Invalid"
            case .Custom6:
                return "Invalid"
            case .Custom7:
                return "Invalid"
            case .Custom8:
                return "Invalid"
            case .Custom9:
                return "Invalid"
            case .Custom10:
                return "Invalid"
            case .Custom11:
                return "Invalid"
        }
    }

    public var name: String {
        switch self {
            case .Texcoord:
                return "uv"
            default:
                return String(describing: self).camelCase
        }
    }

    public var shaderDefine: String {
        "HAS_" + name.uppercased()
    }

    var bufferIndex: VertexBufferIndex {
        switch self {
            case .Position:
                return .Position
            case .Normal:
                return .Normal
            case .Texcoord:
                return .Texcoord
            case .Tangent:
                return .Tangent
            case .Bitangent:
                return .Bitangent
            case .Color:
                return .Color
            case .Anisotropy:
                return .Anisotropy
            case .Binormal:
                return .Binormal
            case .Occlusion:
                return .Occlusion
            case .EdgeCrease:
                return .Occlusion
            case .JointIndices:
                return .Occlusion
            case .JointWeights:
                return .Occlusion
            case .ShadingBasisU:
                return .Occlusion
            case .ShadingBasisV:
                return .Occlusion
            case .SubdivisionStencil:
                return .Occlusion
            case .Custom0:
                return .Custom0
            case .Custom1:
                return .Custom1
            case .Custom2:
                return .Custom2
            case .Custom3:
                return .Custom3
            case .Custom4:
                return .Custom4
            case .Custom5:
                return .Custom5
            case .Custom6:
                return .Custom6
            case .Custom7:
                return .Custom7
            case .Custom8:
                return .Custom8
            case .Custom9:
                return .Custom9
            case .Custom10:
                return .Custom10
            case .Custom11:
                return .Custom11
        }
    }
}

public enum VertexTextureIndex: Int {
    case Custom0 = 0
    case Custom1 = 1
    case Custom2 = 2
    case Custom3 = 3
    case Custom4 = 4
    case Custom5 = 5
    case Custom6 = 6
    case Custom7 = 7
    case Custom8 = 8
    case Custom9 = 9
    case Custom10 = 10
    case Custom11 = 11
    case Custom12 = 12
    case Custom13 = 13
    case Custom14 = 14
    case Custom15 = 15
    case Custom16 = 16
}
