//
//  Attribute.swift
//
//
//  Created by Reza Ali on 7/13/23.
//

import Foundation
import Metal

public enum AttributeType: String, Codable {
    case bool
    case uint16
    case uint32
    case long
    case int
    case int2
    case int3
    case int4
    case float
    case float2
    case float3
    case float4
    case packedfloat3
    case generic

    var format: MTLVertexFormat {
        switch self {
            case .bool:
                return .invalid
            case .uint16:
                return .invalid
            case .uint32:
                return .uint
            case .long:
                return .invalid
            case .int:
                return .int
            case .int2:
                return .int2
            case .int3:
                return .int3
            case .int4:
                return .int4
            case .float:
                return .float
            case .float2:
                return .float2
            case .float3:
                return .float3
            case .float4:
                return .float4
            case .packedfloat3:
                return .float3
            case .generic:
                return .invalid
        }
    }
}

public protocol VertexAttribute: Codable, Equatable, AnyObject {
    associatedtype ValueType: Codable
    var id: String { get }

    var type: AttributeType { get }
    var format: MTLVertexFormat { get }
    var count: Int { get } // this represents how many elements we have in a BufferAttribute (5 positions) or how many vertices we have in an InterleavedBufferAttribute

    var size: Int { get }
    var stride: Int { get }
    var alignment: Int { get }
    var components: Int { get }
}

public protocol BufferAttribute: VertexAttribute {
    var data: [ValueType] { get set }

    var length: Int { get }
    var delegate: BufferAttributeDelegate? { get set }

    func makeBuffer(device: MTLDevice) -> MTLBuffer?
}

public protocol InterleavedBufferAttribute: VertexAttribute {
    var buffer: InterleavedBuffer { get }
    var offset: Int { get }
}
