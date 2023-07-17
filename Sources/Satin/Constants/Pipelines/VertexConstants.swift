//
//  VertexFunctionConstants.swift
//  
//
//  Created by Reza Ali on 3/17/23.
//

import Foundation

public enum VertexBufferIndex: Int, CaseIterable, Codable {
    case Vertices = 0

    case VertexUniforms = 1
    case InstanceMatrixUniforms = 2
    case MaterialUniforms = 3
    case ShadowMatrices = 4

    case Positions = 5
    case Normals = 6
    case Texcoords = 7
    case Tangents = 8
    case Bitangents = 9
    case Colors = 10

    case Custom0 = 11
    case Custom1 = 12
    case Custom2 = 13
    case Custom3 = 14
    case Custom4 = 15
    case Custom5 = 16
    case Custom6 = 17
    case Custom7 = 18
    case Custom8 = 19
    case Custom9 = 20
    case Custom10 = 21
    case Custom11 = 22

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

    case Custom0 = 6
    case Custom1 = 7
    case Custom2 = 8
    case Custom3 = 9
    case Custom4 = 10
    case Custom5 = 11
    case Custom6 = 12
    case Custom7 = 13
    case Custom8 = 14
    case Custom9 = 15
    case Custom10 = 16
    case Custom11 = 17

    public var description: String {
        String(describing: self).titleCase
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
                return VertexBufferIndex.Positions
            case .Normal:
                return VertexBufferIndex.Normals
            case .Texcoord:
                return VertexBufferIndex.Texcoords
            case .Tangent:
                return VertexBufferIndex.Tangents
            case .Bitangent:
                return VertexBufferIndex.Bitangents
            case .Color:
                return VertexBufferIndex.Colors
            case .Custom0:
                return VertexBufferIndex.Custom0
            case .Custom1:
                return VertexBufferIndex.Custom1
            case .Custom2:
                return VertexBufferIndex.Custom2
            case .Custom3:
                return VertexBufferIndex.Custom3
            case .Custom4:
                return VertexBufferIndex.Custom4
            case .Custom5:
                return VertexBufferIndex.Custom5
            case .Custom6:
                return VertexBufferIndex.Custom6
            case .Custom7:
                return VertexBufferIndex.Custom7
            case .Custom8:
                return VertexBufferIndex.Custom8
            case .Custom9:
                return VertexBufferIndex.Custom9
            case .Custom10:
                return VertexBufferIndex.Custom10
            case .Custom11:
                return VertexBufferIndex.Custom11
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
