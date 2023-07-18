//
//  File.swift
//  
//
//  Created by Reza Ali on 7/13/23.
//

import Foundation
import Metal
import simd

public class GenericInterleavedBufferAttribute<T: Codable>: InterleavedBufferAttribute {
    public var id: String = UUID().uuidString
    public var buffer: InterleavedBuffer
    public var offset: Int

    public typealias ValueType = T

    // Getable Properties
    public var type: AttributeType { .generic }
    public var format: MTLVertexFormat { type.format }
    public var count: Int { buffer.count }
    
    // Computed Properties
    public var size: Int { return MemoryLayout<ValueType>.size }
    public var stride: Int { return MemoryLayout<ValueType>.stride }
    public var alignment: Int { return MemoryLayout<ValueType>.alignment }

    public var components: Int { 0 }

    public init(buffer: InterleavedBuffer, offset: Int) {
        self.buffer = buffer
        self.offset = offset
    }

    public static func == (lhs: GenericInterleavedBufferAttribute<T>, rhs: GenericInterleavedBufferAttribute<T>) -> Bool {
        lhs === rhs
    }
}

public final class FloatInterleavedBufferAttribute: GenericInterleavedBufferAttribute<Float> {
    override public var type: AttributeType { .float }
    override public var components: Int { 1 }
}

public final class Float2InterleavedBufferAttribute: GenericInterleavedBufferAttribute<simd_float2> {
    override public var type: AttributeType { .float2 }
    override public var components: Int { simd_float2.scalarCount }
}

public final class Float3InterleavedBufferAttribute: GenericInterleavedBufferAttribute<simd_float3> {
    override public var type: AttributeType { .float3 }
    override public var components: Int { simd_float3.scalarCount }
}

public final class Float4InterleavedBufferAttribute: GenericInterleavedBufferAttribute<simd_float4> {
    override public var type: AttributeType { .float4 }
    override public var components: Int { simd_float4.scalarCount }
}

public final class PackedFloat3InterleavedBufferAttribute: GenericInterleavedBufferAttribute<simd_float3> {
    override public var type: AttributeType { .packedfloat3 }
    override public var components: Int { simd_float3.scalarCount }

    override public var size: Int { return 12 }
    override public var stride: Int { return 12 }
    override public var alignment: Int { return 4 }
}
