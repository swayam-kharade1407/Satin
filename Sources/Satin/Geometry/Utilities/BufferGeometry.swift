//
//  BufferGeometry.swift
//
//
//  Created by Reza Ali on 7/13/23.
//

import Foundation
import Combine
import Metal
import SatinCore

// add codable to this (encode & decode)


public class BufferGeometry: BufferAttributeDelegate {
    public var id: String = UUID().uuidString

    public var context: Context? {
        didSet {
            guard let context = context, context != oldValue else { return }
            setup()
        }
    }

    public var windingOrder: MTLWinding = .counterClockwise
    public var primitiveType: MTLPrimitiveType = .triangle {
        didSet {
            if primitiveType != oldValue, primitiveType != .triangle {
                _bvh.clear()
                _bounds.clear()
            }
        }
    }

    private var _vertexDescriptor = ValueCache<MTLVertexDescriptor>()
    public var vertexDescriptor: MTLVertexDescriptor { _vertexDescriptor.get { generateVertexDescriptor() } }

    public private(set) var vertexAttributes: [VertexAttributeIndex: any VertexAttribute] = [:] {
        didSet {
            _updateVertexBuffers = true
            _vertexDescriptor.clear()
        }
    }

    public var vertexCount: Int { vertexAttributes[.Position]?.count ?? 0 }
    public private(set) var vertexBuffers: [VertexBufferIndex: MTLBuffer?] = [:]

    private var _updateVertexBuffers = true {
        didSet {
            if _updateVertexBuffers {
                _bounds.clear()
                _bvh.clear()
            }
        }
    }

    public var indexData: [UInt32] = [] {
        didSet {
            _updateIndexBuffer = true
        }
    }

    public var indexType: MTLIndexType { .uint32 }
    public var indexCount: Int { indexData.count }

    public private(set) var indexBuffer: MTLBuffer? {
        didSet {
            _updateIndexBuffer = false
        }
    }

    private var _bvh = ValueCache<BVH>()
    public var bvh: BVH? {
        if primitiveType == .triangle {
            return _bvh.get { createBVH() }
        }
        return nil
    }

    private var _updateBounds = true {
        didSet {
            if _updateBounds {
                _bvh.clear()
            }
        }
    }

    private var _bounds = ValueCache<Bounds>()
    public var bounds: Bounds {
        _bounds.get { computeBounds() }
    }

    private var _updateIndexBuffer = true {
        didSet {
            if _updateIndexBuffer {
                _bounds.clear()
                _bvh.clear()
            }
        }
    }

    public let updatePublisher = PassthroughSubject<BufferGeometry, Never>()

    public init() {}

    open func setup() {
        updateBuffers()
    }

    open func update(_ commandBuffer: MTLCommandBuffer) {
        updateBuffers()
    }

    // MARK: - Attributes

    public func getAttribute(_ index: VertexAttributeIndex) -> (any VertexAttribute)? {
        vertexAttributes[index]
    }

    public func setAttribute(_ attribute: any VertexAttribute, for index: VertexAttributeIndex) {
        vertexAttributes[index] = attribute
        if let bufferAttribute = attribute as? any BufferAttribute {
            bufferAttribute.delegate = self
        }
    }

    private func updateBuffers() {
        if _updateVertexBuffers {
            setupVertexBuffers()
        }
        if _updateIndexBuffer {
            setupIndexBuffer()
        }
    }

    private func setupVertexBuffers() {
        guard let device = context?.device else { return }
        for (attributeIndex, attribute) in vertexAttributes {
            if let bufferAttribute = attribute as? any BufferAttribute {
                setupBufferAttribute(device, attribute: bufferAttribute, for: attributeIndex)
            }
            else if let interleavedBufferAttribute = attribute as? any InterleavedBufferAttribute {
                setupInterleavedBufferAttribute(device, attribute: interleavedBufferAttribute)
            }
        }
        _updateVertexBuffers = false
    }

    private func setupIndexBuffer() {
        guard let device = context?.device else { return }
        if !indexData.isEmpty {
            let indicesSize = indexData.count * MemoryLayout.size(ofValue: indexData[0])
            indexBuffer = device.makeBuffer(bytes: indexData, length: indicesSize, options: [])
            indexBuffer?.label = "Indices"
        }
        else {
            indexBuffer = nil
        }
    }

    // MARK: - Setup Vertex Attributes

    private func setupBufferAttribute(_ device: MTLDevice, attribute: any BufferAttribute, for index: VertexAttributeIndex) {
        let bufferIndex = index.bufferIndex
        vertexBuffers[bufferIndex] = attribute.makeBuffer(device: device)
    }

    private func setupInterleavedBufferAttribute(_ device: MTLDevice, attribute: any InterleavedBufferAttribute) {
        let buffer = attribute.buffer
        let bufferIndex = buffer.index

        guard vertexBuffers[bufferIndex] == nil else { return }
        vertexBuffers[bufferIndex] = device.makeBuffer(bytes: buffer.data, length: buffer.length)
    }

    // MARK: - Vertex Descriptor

    private func generateVertexDescriptor() -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()

        for (attributeIndex, attribute) in vertexAttributes {
            if let interleavedAttribute = attribute as? any InterleavedBufferAttribute {
                let index = attributeIndex.rawValue
                let buffer = interleavedAttribute.buffer
                let bufferIndex = buffer.index.rawValue

                descriptor.attributes[index].format = interleavedAttribute.format
                descriptor.attributes[index].offset = interleavedAttribute.offset
                descriptor.attributes[index].bufferIndex = bufferIndex

                descriptor.layouts[bufferIndex].stride = buffer.stride
                descriptor.layouts[bufferIndex].stepRate = buffer.stepRate
                descriptor.layouts[bufferIndex].stepFunction = buffer.stepFunction
            }
            else {
                let index = attributeIndex.rawValue
                let bufferIndex = attributeIndex.bufferIndex.rawValue
                descriptor.attributes[index].format = attribute.format
                descriptor.attributes[index].offset = 0
                descriptor.attributes[index].bufferIndex = bufferIndex

                descriptor.layouts[bufferIndex].stride = attribute.stride
                descriptor.layouts[bufferIndex].stepRate = 1
                descriptor.layouts[bufferIndex].stepFunction = .perVertex
            }
        }

        return descriptor
    }

    // MARK: - BVH

    private func createBVH() -> BVH {
        guard let positionAttribute = vertexAttributes[.Position] else { return BVH() }

        if let positionBufferAttribute = positionAttribute as? Float4BufferAttribute {
            return createBVHFromFloatData(
                &positionBufferAttribute.data,
                Int32(positionBufferAttribute.stride/MemoryLayout<Float>.size),
                Int32(positionBufferAttribute.count),
                &indexData,
                Int32(indexCount),
                false
            )
        }
        else if let positionBufferAttribute = positionAttribute as? Float3BufferAttribute {
            return createBVHFromFloatData(
                &positionBufferAttribute.data,
                Int32(positionBufferAttribute.stride/MemoryLayout<Float>.size),
                Int32(positionBufferAttribute.count),
                &indexData,
                Int32(indexCount),
                false
            )
        }
        else if let interleavedBufferAttribute = positionAttribute as? (any InterleavedBufferAttribute) {
            let buffer = interleavedBufferAttribute.buffer
            return createBVHFromFloatData(
                buffer.data,
                Int32(buffer.stride/MemoryLayout<Float>.size),
                Int32(buffer.count),
                &indexData,
                Int32(indexCount),
                false
            )
        }
        else {
            return BVH()
        }
    }

    // MARK: - Bounds

    func computeBounds() -> Bounds {
        if primitiveType == .triangle, let bvh = bvh, let node = bvh.getNode(index: 0) {
            return node.aabb
        }
        else if let positionAttribute = vertexAttributes[.Position] {
            if let positionBufferAttribute = positionAttribute as? Float4BufferAttribute {
                return computeBoundsFromFloatData(
                    &positionBufferAttribute.data,
                    Int32(positionBufferAttribute.stride/MemoryLayout<Float>.size),
                    Int32(positionBufferAttribute.count)
                )
            }
            else if let positionBufferAttribute = positionAttribute as? Float3BufferAttribute {
                return computeBoundsFromFloatData(
                    &positionBufferAttribute.data,
                    Int32(positionBufferAttribute.stride/MemoryLayout<Float>.size),
                    Int32(positionBufferAttribute.count)
                )
            }
            else if let interleavedBufferAttribute = positionAttribute as? (any InterleavedBufferAttribute) {
                let buffer = interleavedBufferAttribute.buffer
                return computeBoundsFromFloatData(
                    buffer.data,
                    Int32(buffer.stride/MemoryLayout<Float>.size),
                    Int32(buffer.count)
                )
            }
        }

        return createBounds()
    }

    // MARK: - Intersects

    public func intersects(ray: Ray) -> Bool {
        return rayBoundsIntersect(ray, bounds)
    }

    public func intersect(ray: Ray, intersections: inout [IntersectionResult]) {
        bvh?.intersect(ray: ray, intersections: &intersections)
    }

    // MARK: - Deinit

    deinit {
        vertexAttributes.removeAll()
        vertexBuffers.removeAll()
        indexData.removeAll()
        indexBuffer = nil

        _bvh.clear()
        _bounds.clear()
    }

    // MARK: - Updated Buffer Attribute Data

    public func updated(attribute: any BufferAttribute) {
        guard let device = context?.device else { return }

        var index: VertexAttributeIndex?

        for (attributeIndex, vertexAttribute) in vertexAttributes {
            if vertexAttribute === attribute {
                index = attributeIndex
                break
            }
        }

        guard let index = index else { return }
        setupBufferAttribute(device, attribute: attribute, for: index)
    }
}

extension BufferGeometry: Equatable {
    public static func == (lhs: BufferGeometry, rhs: BufferGeometry) -> Bool {
        return lhs === rhs
    }
}

extension BufferGeometry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
