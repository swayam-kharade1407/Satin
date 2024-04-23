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
    var defaultValue: ValueType { get set }
    var data: [ValueType] { get set }
    var buffer: MTLBuffer? { get }

    var length: Int { get }

    subscript<ValueType>(index: Int) -> ValueType { get set }

    var needsUpdate: Bool { get set }
    var delegate: BufferAttributeDelegate? { get set }

    func resize(_ capacity: Int)
    func expand(_ size: Int)
    func append(_ value: ValueType)
    func append(contentsOf array: [ValueType])
    func getBuffer(device: MTLDevice) -> MTLBuffer?
    func getData() -> Data
    func duplicate() -> any BufferAttribute
    func duplicate(at index: Int)
    func remove(at index: Int)
    func removeLast()
    func removeLast(_ k: Int)
    func reserveCapacity(_ minimumCapacity: Int)

    func interpolate(start: Int, end: Int, at time: Float)
    func set(at: Int, from: Int, source: any BufferAttribute)

    init(defaultValue: ValueType, data: [ValueType], stepRate: Int, stepFunction: MTLVertexStepFunction)
    init(defaultValue: ValueType, count: Int, stepRate: Int, stepFunction: MTLVertexStepFunction)
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

    public var defaultValue: ValueType

    public var data: [ValueType] {
        didSet {
            needsUpdate = true
            delegate?.updated(attribute: self)
        }
    }

    public var buffer: MTLBuffer?

    public let stepRate: Int
    public let stepFunction: MTLVertexStepFunction

    public required init(defaultValue: ValueType, data: [ValueType], stepRate: Int = 1, stepFunction: MTLVertexStepFunction = .perVertex) {
        self.defaultValue = defaultValue
        self.data = data
        self.stepRate = stepRate
        self.stepFunction = stepFunction
    }

    public required init(defaultValue: ValueType, count: Int = 0, stepRate: Int = 1, stepFunction: MTLVertexStepFunction = .perVertex) {
        self.defaultValue = defaultValue
        self.data = Array(repeating: defaultValue, count: count)
        self.stepRate = stepRate
        self.stepFunction = stepFunction
    }

    private enum CodingKeys: String, CodingKey {
        case defaultValue
        case data
        case count
        case stepRate
        case stepFunction
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let count = try container.decode(Int.self, forKey: .count)
        self.defaultValue = try container.decode(ValueType.self, forKey: .defaultValue)
        let bytes = try container.decode(Data.self, forKey: .data)
        var data: [ValueType] = []
        bytes.withUnsafeBytes { ptr in
            let typedPtr = ptr.baseAddress?.assumingMemoryBound(to: ValueType.self)
            data = Array(UnsafeBufferPointer(start: typedPtr, count: count))
        }
        self.data = data

        self.stepRate = try container.decodeIfPresent(Int.self, forKey: .stepRate) ?? 1
        self.stepFunction = try container.decodeIfPresent(MTLVertexStepFunction.self, forKey: .stepFunction) ?? .perVertex
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(count, forKey: .count)
        try container.encode(defaultValue, forKey: .defaultValue)
        try container.encode(getData(), forKey: .data)
    }

    public func getBuffer(device: MTLDevice) -> MTLBuffer? {
        guard length > 0 else { return nil }

        if needsUpdate {
            buffer = device.makeBuffer(bytes: data, length: length)
            needsUpdate = false
        }

        return buffer
    }

    public func getData() -> Data {
        return Data(bytes: &data, count: length)
    }

    public func append(_ value: ValueType) {
        data.append(value)
    }

    public func resize(_ capacity: Int) {
        if data.count < capacity {
            expand(capacity - data.count)
        }
        else if data.count > capacity {
            removeLast(data.count - capacity)
        }
    }

    public func expand(_ size: Int = 1) {
        data.reserveCapacity(data.count + size)
        data.append(contentsOf: Array(repeating: defaultValue, count: size))
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
        return GenericBufferAttribute<ValueType>(defaultValue: defaultValue, data: data)
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

    public func removeLast(_ k: Int) {
        data.removeLast(k)
    }

    public func interpolate(start: Int, end: Int, at time: Float) {
        fatalError("")
    }

    public func set(at: Int, from: Int, source: any BufferAttribute) {
        if let sourceBuffer = source as? GenericBufferAttribute<T> {
            data[at] = sourceBuffer[from]
        }
    }
}

public final class BoolBufferAttribute: GenericBufferAttribute<Bool> {
    override public var type: AttributeType { .bool }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return BoolBufferAttribute(defaultValue: defaultValue, data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(time > 0.5 ? data[end] : data[start])
    }
}

public final class UInt16BufferAttribute: GenericBufferAttribute<UInt16> {
    override public var type: AttributeType { .uint16 }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return UInt16BufferAttribute(defaultValue: defaultValue, data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(UInt16(simd_mix(Float(data[start]), Float(data[end]), time)))
    }
}

public final class UInt32BufferAttribute: GenericBufferAttribute<UInt32> {
    override public var type: AttributeType { .uint32 }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return UInt32BufferAttribute(defaultValue: defaultValue, data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(UInt32(simd_mix(Float(data[start]), Float(data[end]), time)))
    }
}

public final class IntBufferAttribute: GenericBufferAttribute<simd_int1> {
    override public var type: AttributeType { .int }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return IntBufferAttribute(defaultValue: defaultValue, data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(Int32(simd_mix(Float(data[start]), Float(data[end]), time)))
    }
}

public final class Int2BufferAttribute: GenericBufferAttribute<simd_int2> {
    override public var type: AttributeType { .int2 }
    override public var components: Int { 2 }

    override public func duplicate() -> any BufferAttribute {
        return Int2BufferAttribute(defaultValue: defaultValue, data: data)
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
        return Int3BufferAttribute(defaultValue: defaultValue, data: data)
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
        return Int4BufferAttribute(defaultValue: defaultValue, data: data)
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
        return LongBufferAttribute(defaultValue: defaultValue, data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(Int(simd_mix(Float(data[start]), Float(data[end]), time)))
    }
}

public final class FloatBufferAttribute: GenericBufferAttribute<simd_float1> {
    override public var type: AttributeType { .float }
    override public var components: Int { 1 }

    override public func duplicate() -> any BufferAttribute {
        return FloatBufferAttribute(defaultValue: defaultValue, data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(simd_mix(data[start], data[end], time))
    }
}

public final class Float2BufferAttribute: GenericBufferAttribute<simd_float2> {
    override public var type: AttributeType { .float2 }
    override public var components: Int { 2 }

    override public func duplicate() -> any BufferAttribute {
        return Float2BufferAttribute(defaultValue: defaultValue, data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(simd_mix(data[start], data[end], simd_float2(repeating: time)))
    }
}

public final class Float3BufferAttribute: GenericBufferAttribute<simd_float3> {
    override public var type: AttributeType { .float3 }
    override public var components: Int { 3 }

    override public func duplicate() -> any BufferAttribute {
        return Float3BufferAttribute(defaultValue: defaultValue, data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(simd_mix(data[start], data[end], simd_float3(repeating: time)))
    }
}

public final class Float4BufferAttribute: GenericBufferAttribute<simd_float4> {
    override public var type: AttributeType { .float4 }
    override public var components: Int { 4 }

    override public func duplicate() -> any BufferAttribute {
        return Float4BufferAttribute(defaultValue: defaultValue, data: data)
    }

    override public func interpolate(start: Int, end: Int, at time: Float) {
        append(simd_mix(data[start], data[end], simd_float4(repeating: time)))
    }
}

public final class PackedFloat3BufferAttribute: GenericBufferAttribute<MTLPackedFloat3> {
    override public var type: AttributeType { .float3 }
    override public var components: Int { 3 }

    override public func duplicate() -> any BufferAttribute {
        return PackedFloat3BufferAttribute(defaultValue: defaultValue, data: data)
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
