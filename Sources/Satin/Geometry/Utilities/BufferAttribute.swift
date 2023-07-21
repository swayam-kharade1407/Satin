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
    public let id: String = UUID().uuidString

    public typealias ValueType = T

    // Update & Delegate
    public var needsUpdate: Bool = true
    public weak var delegate: BufferAttributeDelegate?

    // Getable Properties
    public var type: AttributeType { .generic }
    public var format: MTLVertexFormat { type.format }

    // Computed Properties
    public var size: Int { return MemoryLayout<T>.size }
    public var stride: Int { return MemoryLayout<T>.stride }
    public var alignment: Int { return MemoryLayout<T>.alignment }

    public var components: Int { 0 }
    public var count: Int { data.count }

    public var length: Int { count * stride }

    public var data: [ValueType] {
        didSet {
            needsUpdate = true
            delegate?.updated(attribute: self)
        }
    }

    public init(data: [ValueType]) {
        self.data = data
    }

    public func makeBuffer(device: MTLDevice) -> MTLBuffer? {
        guard length > 0 else { return nil }
        return device.makeBuffer(bytes: &data, length: length)
    }

    public static func == (lhs: GenericBufferAttribute<T>, rhs: GenericBufferAttribute<T>) -> Bool {
        lhs === rhs
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

public final class PackedFloat3BufferAttribute: GenericBufferAttribute<MTLPackedFloat3> {
    override public var type: AttributeType { .float3 }
    override public var components: Int { 3 }
}
