//
//  BufferAttribute.swift
//  
//
//  Created by Reza Ali on 7/13/23.
//

import Foundation
import Metal
import simd

public protocol BufferAttributeDelegate: AnyObject {
    func updated(attribute: any BufferAttribute)
}

public class GenericBufferAttribute<T: Codable>: BufferAttribute, Equatable {
    public var id: String = UUID().uuidString

    public typealias ValueType = T

    // Delegate
    public weak var delegate: BufferAttributeDelegate?

    // Getable Properties
    public var type: AttributeType { .generic }
    public var format: MTLVertexFormat { type.format }

    // Computed Properties
    public var size: Int { return MemoryLayout<ValueType>.size }
    public var stride: Int { return MemoryLayout<ValueType>.stride }
    public var alignment: Int { return MemoryLayout<ValueType>.alignment }

    public var components: Int { 0 }
    public var count: Int { data.count }

    public var length: Int { count * stride }

    public var data: [ValueType] {
        didSet {
            delegate?.updated(attribute: self)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case index
        case data
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([ValueType].self, forKey: .data)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
    }

    public init(data: [ValueType]) {
        self.data = data
    }

    public func makeBuffer(device: MTLDevice) -> MTLBuffer? {
        device.makeBuffer(bytes: &data, length: length)
    }

    public static func == (lhs: GenericBufferAttribute<T>, rhs: GenericBufferAttribute<T>) -> Bool {
        lhs.id == rhs.id
    }
}

public final class BoolBufferAttribute: GenericBufferAttribute<Bool> {
    override public var type: AttributeType { .bool }
    override public var components: Int { 1 }
}

public final class UInt16BufferAttribute: GenericBufferAttribute<UInt16> {
    override public var type: AttributeType { .uint16 }
    override public var components: Int { 1 }
}

public final class UInt32BufferAttribute: GenericBufferAttribute<UInt32> {
    override public var type: AttributeType { .uint32 }
    override public var components: Int { 1 }
}

public final class IntBufferAttribute: GenericBufferAttribute<simd_int1> {
    override public var type: AttributeType { .int }
    override public var components: Int { 1 }
}

public final class Int2BufferAttribute: GenericBufferAttribute<simd_int2> {
    override public var type: AttributeType { .int2 }
    override public var components: Int { 2 }
}

public final class Int3BufferAttribute: GenericBufferAttribute<simd_int3> {
    override public var type: AttributeType { .int3 }
    override public var components: Int { 3 }
}

public final class Int4BufferAttribute: GenericBufferAttribute<simd_int4> {
    override public var type: AttributeType { .int4 }
    override public var components: Int { 4 }
}

public final class LongBufferAttribute: GenericBufferAttribute<Int> {
    override public var type: AttributeType { .long }
    override public var components: Int { 1 }
}

public final class FloatBufferAttribute: GenericBufferAttribute<simd_float1> {
    override public var type: AttributeType { .float }
    override public var components: Int { 1 }
}

public final class Float2BufferAttribute: GenericBufferAttribute<simd_float2> {
    override public var type: AttributeType { .float2 }
    override public var components: Int { 2 }
}

public final class Float3BufferAttribute: GenericBufferAttribute<simd_float3> {
    override public var type: AttributeType { .float3 }
    override public var components: Int { 3 }
}

public final class Float4BufferAttribute: GenericBufferAttribute<simd_float4> {
    override public var type: AttributeType { .float4 }
    override public var components: Int { 4 }
}

public final class PackedFloat3BufferAttribute: GenericBufferAttribute<simd_float3> {
    override public var type: AttributeType { .packedfloat3 }
    override public var components: Int { 3 }

    override public var size: Int { return 12 }
    override public var stride: Int { return 12 }
    override public var alignment: Int { return 4 }
}
