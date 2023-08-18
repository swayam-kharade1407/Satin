//
//  BufferAttribute.swift
//
//
//  Created by Reza Ali on 7/13/23.
//

import Combine
import Foundation
import Metal
import simd

public protocol BufferAttribute: VertexAttribute, Codable {
    var data: [ValueType] { get set }

    var length: Int { get }

    subscript<ValueType>(_: Int) -> ValueType { get set }

    var needsUpdate: Bool { get set }
    var delegate: BufferAttributeDelegate? { get set }

    func append(_ value: ValueType)
    func append(contentsOf array: [ValueType])
    func makeBuffer(device: MTLDevice) -> MTLBuffer?
    func getData() -> Data
    func duplicate() -> any BufferAttribute
    func duplicate(at index: Int)
    func remove(at index: Int)
    func removeLast()
    func reserveCapacity(_ minimumCapacity: Int)

    func interpolate(start: Int, end: Int, at time: Float)

    init()
    init(data: [ValueType])
    init(defaultValue: ValueType, count: Int)
}

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

    public subscript<ValueType>(index: Int) -> ValueType {
        get {
            return data[index] as! ValueType
        }
        set {
            data[index] = newValue as! T
        }
    }

    public var data: [ValueType] {
        didSet {
            needsUpdate = true
            delegate?.updated(attribute: self)
        }
    }

    public required init() {
        self.data = []
    }

    required public init(data: [ValueType]) {
        self.data = data
    }

    required public init(defaultValue: ValueType, count: Int) {
        self.data = Array(repeating: defaultValue, count: count)
    }

    private enum CodingKeys: String, CodingKey {
        case count
        case data
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let count = try container.decode(Int.self, forKey: .count)
        let bytes = try container.decode(Data.self, forKey: .data)
        var data: [ValueType] = []
        bytes.withUnsafeBytes { ptr in
            let typedPtr = ptr.baseAddress?.assumingMemoryBound(to: ValueType.self)
            data = Array(UnsafeBufferPointer(start: typedPtr, count: count))
        }
        self.data = data
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(count, forKey: .count)
        try container.encode(getData(), forKey: .data)
    }

    public func makeBuffer(device: MTLDevice) -> MTLBuffer? {
        guard length > 0 else { return nil }
        return device.makeBuffer(bytes: &data, length: length)
    }

    public func getData() -> Data {
        return Data(bytes: &data, count: length)
    }

    public func append(_ value: ValueType) {
        data.append(value)
    }

    public func append(contentsOf array: [ValueType]) {
        data.append(contentsOf: array)
    }

    public func reserveCapacity(_ minimumCapacity: Int) {
        data.reserveCapacity(minimumCapacity)
    }

    public static func == (lhs: GenericBufferAttribute<T>, rhs: GenericBufferAttribute<T>) -> Bool {
        lhs === rhs
    }

    public func duplicate() -> any BufferAttribute {
        return GenericBufferAttribute<ValueType>(data: data)
    }

    public func duplicate(at index: Int) {
        data.append(data[index])
    }

    public func remove(at index: Int) {
        data.remove(at: index)
    }

    public func removeLast() {
        data.removeLast()
    }

    public func interpolate(start: Int, end: Int, at time: Float) {
        fatalError("")
    }
}

public final class BoolBufferAttribute: GenericBufferAttribute<Bool> {
    override public var type: AttributeType { .bool }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return BoolBufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(time > 0.5 ? data[end] : data[start])
    }
}

public final class UInt16BufferAttribute: GenericBufferAttribute<UInt16> {
    override public var type: AttributeType { .uint16 }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return UInt16BufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(UInt16(simd_mix(Float(data[start]), Float(data[end]), time)))
    }
}

public final class UInt32BufferAttribute: GenericBufferAttribute<UInt32> {
    override public var type: AttributeType { .uint32 }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return UInt32BufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(UInt32(simd_mix(Float(data[start]), Float(data[end]), time)))
    }
}

public final class IntBufferAttribute: GenericBufferAttribute<simd_int1> {
    override public var type: AttributeType { .int }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return IntBufferAttribute(data: data)
    }
    
    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(Int32(simd_mix(Float(data[start]), Float(data[end]), time)))
    }
}

public final class Int2BufferAttribute: GenericBufferAttribute<simd_int2> {
    override public var type: AttributeType { .int2 }
    override public var components: Int { 2 }

    override public func duplicate() -> any BufferAttribute {
        return Int2BufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        let startValue = data[start]
        let endValue = data[end]
        append(
            simd_make_int2(
                Int32(simd_mix(Float(startValue.x), Float(endValue.x), time)),
                Int32(simd_mix(Float(startValue.y), Float(endValue.y), time))
            )
        )
    }
}

public final class Int3BufferAttribute: GenericBufferAttribute<simd_int3> {
    override public var type: AttributeType { .int3 }
    override public var components: Int { 3 }

    override public func duplicate() -> any BufferAttribute {
        return Int3BufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        let startValue = data[start]
        let endValue = data[end]
        append(
            simd_make_int3(
                Int32(simd_mix(Float(startValue.x), Float(endValue.x), time)),
                Int32(simd_mix(Float(startValue.y), Float(endValue.y), time)),
                Int32(simd_mix(Float(startValue.z), Float(endValue.z), time))
            )
        )
    }
}

public final class Int4BufferAttribute: GenericBufferAttribute<simd_int4> {
    override public var type: AttributeType { .int4 }
    override public var components: Int { 4 }

    override public func duplicate() -> any BufferAttribute {
        return Int4BufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        let startValue = data[start]
        let endValue = data[end]
        append(
            simd_make_int4(
                Int32(simd_mix(Float(startValue.x), Float(endValue.x), time)),
                Int32(simd_mix(Float(startValue.y), Float(endValue.y), time)),
                Int32(simd_mix(Float(startValue.z), Float(endValue.z), time)),
                Int32(simd_mix(Float(startValue.z), Float(endValue.z), time))
            )
        )
    }
}

public final class LongBufferAttribute: GenericBufferAttribute<Int> {
    override public var type: AttributeType { .long }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return LongBufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(Int(simd_mix(Float(data[start]), Float(data[end]), time)))
    }
}

public final class FloatBufferAttribute: GenericBufferAttribute<simd_float1> {
    override public var type: AttributeType { .float }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return FloatBufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(simd_mix(data[start], data[end], time))
    }
}

public final class Float2BufferAttribute: GenericBufferAttribute<simd_float2> {
    override public var type: AttributeType { .float2 }
    override public var components: Int { 2 }

    override public func duplicate() -> any BufferAttribute {
        return Float2BufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(simd_mix(data[start], data[end], simd_float2(repeating: time)))
    }
}

public final class Float3BufferAttribute: GenericBufferAttribute<simd_float3> {
    override public var type: AttributeType { .float3 }
    override public var components: Int { 3 }

    override public func duplicate() -> any BufferAttribute {
        return Float3BufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(simd_mix(data[start], data[end], simd_float3(repeating: time)))
    }
}

public final class Float4BufferAttribute: GenericBufferAttribute<simd_float4> {
    override public var type: AttributeType { .float4 }
    override public var components: Int { 4 }

    override public func duplicate() -> any BufferAttribute {
        return Float4BufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(simd_mix(data[start], data[end], simd_float4(repeating: time)))
    }
}

public final class PackedFloat3BufferAttribute: GenericBufferAttribute<MTLPackedFloat3> {
    override public var type: AttributeType { .float3 }
    override public var components: Int { 3 }

    override public func duplicate() -> any BufferAttribute {
        return PackedFloat3BufferAttribute(data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        let startValue = data[start]
        let endValue = data[end]
        append(
            MTLPackedFloat3Make(
                simd_mix(startValue.x, endValue.x, time),
                simd_mix(startValue.y, endValue.y, time),
                simd_mix(startValue.z, endValue.z, time)
            )
        )
    }
}
