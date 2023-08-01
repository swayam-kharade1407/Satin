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
    case packedfloat3
    case float4
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
            case .packedfloat3:
                return .float3
            case .float4:
                return .float4
            case .generic:
                return .invalid
        }
    }

    var metatype: any BufferAttribute.Type {
        switch self {
            case .float4:
                return Float4BufferAttribute.self
            case .float3:
                return Float3BufferAttribute.self
            case .packedfloat3:
                return PackedFloat3BufferAttribute.self
            case .float2:
                return Float2BufferAttribute.self
            case .float:
                return FloatBufferAttribute.self
            case .int:
                return IntBufferAttribute.self
            case .int2:
                return Int2BufferAttribute.self
            case .int3:
                return Int3BufferAttribute.self
            case .int4:
                return Int4BufferAttribute.self
            case .bool:
                return BoolBufferAttribute.self
            case .uint16:
                return UInt16BufferAttribute.self
            case .uint32:
                return UInt32BufferAttribute.self
            case .long:
                return LongBufferAttribute.self
            default:
                fatalError("Unknown BufferAttribute Type: \(self)")
        }
    }
}

public protocol VertexAttribute: Equatable, AnyObject {
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

public protocol BufferAttribute: VertexAttribute, Codable {
    var data: [ValueType] { get set }

    var length: Int { get }

    subscript<ValueType>(_: Int) -> ValueType { get set }

    var needsUpdate: Bool { get set }
    var delegate: BufferAttributeDelegate? { get set }

    func append(_ value: ValueType)
    func makeBuffer(device: MTLDevice) -> MTLBuffer?
    func getData() -> Data
}

public protocol InterleavedBufferAttribute: VertexAttribute {
    var buffer: InterleavedBuffer { get }
    var offset: Int { get }
}
