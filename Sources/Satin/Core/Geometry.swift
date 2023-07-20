//
//  Geometry.swift
//
//
//  Created by Reza Ali on 7/13/23.
//

import Combine
import Foundation
import Metal

import SatinCore

// add on change publishers for vertex & index data

open class Geometry: BufferAttributeDelegate, InterleavedBufferDelegate, ElementBufferDelegate {
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

    public let onUpdate = PassthroughSubject<Geometry, Never>()

    public var vertexCount: Int { vertexAttributes[.Position]?.count ?? 0 }
    public private(set) var vertexBuffers: [VertexBufferIndex: MTLBuffer?] = [:]

    private var _updateVertexBuffers = true {
        didSet {
            if _updateVertexBuffers {
                _bounds.clear()
                _bvh.clear()
                onUpdate.send(self)
            }
        }
    }

    public internal(set) var elementBuffer: ElementBuffer? {
        didSet {
            if oldValue != elementBuffer, elementBuffer != nil {
                _updateIndexBuffer = true
            }
        }
    }

    public var indexType: MTLIndexType? { elementBuffer?.type }
    public var indexCount: Int { elementBuffer?.count ?? 0 }

    public private(set) var indexBuffer: MTLBuffer? {
        didSet {
            _updateIndexBuffer = false
        }
    }

    private var _updateIndexBuffer = true {
        didSet {
            if _updateIndexBuffer {
                _bounds.clear()
                _bvh.clear()
                onUpdate.send(self)
            }
        }
    }

    private var _bvh = ValueCache<BVH>()
    public var bvh: BVH? {
        if primitiveType == .triangle {
            return _bvh.get { createBVH() }
        }
        return nil
    }

    private var _bounds = ValueCache<Bounds>()
    public var bounds: Bounds {
        _bounds.get { computeBounds() }
    }

    // MARK: - Init

    public init(primitiveType: MTLPrimitiveType = .triangle, windingOrder: MTLWinding = .counterClockwise) {
        self.windingOrder = windingOrder
        self.primitiveType = primitiveType
    }

    open func setup() {
        updateBuffers()
    }

    open func update(camera: Camera, viewport: simd_float4) {
        updateBuffers()
    }

    open func encode(_ commandBuffer: MTLCommandBuffer) {}

    // MARK: - Elements

    public func setElements(_ elementBuffer: ElementBuffer?) {
        if let oldElementBuffer = self.elementBuffer {
            oldElementBuffer.delegate = nil
        }

        self.elementBuffer = elementBuffer
        if let newElementBuffer = self.elementBuffer {
            newElementBuffer.delegate = self
        }
    }

    // MARK: - Attributes

    public func getAttribute(_ index: VertexAttributeIndex) -> (any VertexAttribute)? {
        vertexAttributes[index]
    }

    public func addAttribute(_ attribute: any VertexAttribute, for index: VertexAttributeIndex) {
        vertexAttributes[index] = attribute
        if let bufferAttribute = attribute as? any BufferAttribute {
            bufferAttribute.delegate = self
        }
        else if let interleavedBuffer = attribute as? any InterleavedBufferAttribute {
            interleavedBuffer.buffer.delegate = self
        }
    }

    public func removeAttribute(_ index: VertexAttributeIndex) {
        if let attribute = vertexAttributes[index] {
            if let bufferAttribute = attribute as? any BufferAttribute {
                bufferAttribute.delegate = nil
            }
            vertexAttributes.removeValue(forKey: index)
        }
    }

    public func removeAttributes() {
        for (index, attribute) in vertexAttributes {
            if let bufferAttribute = attribute as? any BufferAttribute {
                bufferAttribute.delegate = nil
            }
            else if let interleavedAttribute = attribute as? (any InterleavedBufferAttribute) {
                interleavedAttribute.buffer.delegate = nil
            }
            vertexAttributes.removeValue(forKey: index)
        }
    }

    public func hasAttribute(_ index: VertexAttributeIndex) -> Bool {
        return vertexAttributes[index] != nil
    }

    // MARK: - Update Buffers

    private func updateBuffers() {
        if _updateVertexBuffers {
            setupVertexBuffers()
        }
        if _updateIndexBuffer {
            setupIndexBuffer()
        }
    }

    // MARK: - Setup Vertex Buffers

    private func setupVertexBuffers() {
        guard let device = context?.device else { return }
        for (attributeIndex, attribute) in vertexAttributes {
            if let bufferAttribute = attribute as? any BufferAttribute, bufferAttribute.needsUpdate {
                setupBufferAttribute(device, attribute: bufferAttribute, for: attributeIndex)
            }
            else if let interleavedBufferAttribute = attribute as? any InterleavedBufferAttribute {
                setupInterleavedBufferAttribute(device, attribute: interleavedBufferAttribute)
            }
        }
        _updateVertexBuffers = false
    }

    // MARK: - Setup Index Buffer

    private func setupIndexBuffer() {
        guard let device = context?.device, let elementBuffer = elementBuffer, elementBuffer.needsUpdate else { return }
        if elementBuffer.count > 0 {
            indexBuffer = device.makeBuffer(bytes: elementBuffer.data, length: elementBuffer.length, options: [])
            if let indexBuffer = indexBuffer {
                indexBuffer.label = "\(id) Indices"
                elementBuffer.needsUpdate = false
            }
        }
        else {
            indexBuffer = nil
            elementBuffer.needsUpdate = false
        }
    }

    // MARK: - Setup Vertex Attributes

    private func setupBufferAttribute(_ device: MTLDevice, attribute: any BufferAttribute, for index: VertexAttributeIndex) {
        let bufferIndex = index.bufferIndex
        if let buffer = attribute.makeBuffer(device: device) {
            buffer.label = index.name
            vertexBuffers[bufferIndex] = buffer
        }
        else {
            vertexBuffers[bufferIndex] = nil
        }

        attribute.needsUpdate = false
    }

    private func setupInterleavedBufferAttribute(_ device: MTLDevice, attribute: any InterleavedBufferAttribute) {
        let buffer = attribute.buffer
        let bufferIndex = buffer.index

        guard buffer.needsUpdate || vertexBuffers[bufferIndex] == nil else { return }
        vertexBuffers[bufferIndex] = device.makeBuffer(bytes: buffer.data, length: buffer.length)
        buffer.needsUpdate = false
    }

    // MARK: - Vertex Descriptor

    open func generateVertexDescriptor() -> MTLVertexDescriptor {
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
                elementBuffer?.data,
                Int32(indexCount),
                elementBuffer?.type == .uint32,
                false
            )
        }
        else if let positionBufferAttribute = positionAttribute as? Float3BufferAttribute {
            return createBVHFromFloatData(
                &positionBufferAttribute.data,
                Int32(positionBufferAttribute.stride/MemoryLayout<Float>.size),
                Int32(positionBufferAttribute.count),
                elementBuffer?.data,
                Int32(indexCount),
                elementBuffer?.type == .uint32,
                false
            )
        }
        else if let interleavedBufferAttribute = positionAttribute as? (any InterleavedBufferAttribute) {
            let buffer = interleavedBufferAttribute.buffer
            return createBVHFromFloatData(
                buffer.data,
                Int32(buffer.stride/MemoryLayout<Float>.size),
                Int32(buffer.count),
                elementBuffer?.data,
                Int32(indexCount),
                elementBuffer?.type == .uint32,
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
        removeAttributes()

        vertexAttributes.removeAll()
        vertexBuffers.removeAll()

        elementBuffer?.delegate = nil
        elementBuffer = nil        
        indexBuffer = nil

        _bvh.clear()
        _bounds.clear()
    }

    // MARK: - Updated Buffer Attribute Data

    public func updated(attribute: any BufferAttribute) {
        _updateVertexBuffers = true
    }

    // MARK: - Updated Interleaved Buffer Data {

    public func updated(buffer: InterleavedBuffer) {
        _updateVertexBuffers = true
    }

    // MARK: - Updated Eleement Buffer Data {

    public func updated(buffer: ElementBuffer) {
        _updateIndexBuffer = true
    }
}

extension Geometry: Equatable {
    public static func == (lhs: Geometry, rhs: Geometry) -> Bool {
        return lhs === rhs
    }
}

extension Geometry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
