//
//  Submesh.swift
//  Satin
//
//  Created by Reza Ali on 5/25/20.
//

import Combine
import Metal
import simd

open class Submesh {
    public var id: String = UUID().uuidString
    public var label = "Submesh"
    open var context: Context? {
        didSet {
            if context != nil {
                setup()
            }
        }
    }

    public var visible = true

    public var offset = 0
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

    private var _updateIndexBuffer = true

    weak var parent: Mesh?
    var material: Material?

    public init(
        label: String = "Submesh",
        parent: Mesh,
        elementBuffer: ElementBuffer,
        offset: Int = 0,
        material: Material? = nil
    ) {
        self.parent = parent
        self.elementBuffer = elementBuffer
        self.offset = offset
        self.material = material
    }

    private func setup() {
        updateBuffer()
        setupMaterial()
    }

    func updateBuffer() {
        if _updateIndexBuffer {
            setupIndexBuffer()
        }
    }

    open func update(camera: Camera, viewport: simd_float4) {
        updateBuffer()
        material?.update(camera: camera, viewport: viewport)
    }

    open func encode(_ commandBuffer: MTLCommandBuffer) {
        material?.encode(commandBuffer)
    }

    private func setupMaterial() {
        guard let context = context, let material = material, let parent = parent else { return }
        material.vertexDescriptor = parent.geometry.vertexDescriptor
        material.context = context
    }

    private func setupIndexBuffer() {
        guard let device = context?.device, let elementBuffer = elementBuffer, elementBuffer.needsUpdate else { return }

        if elementBuffer.count > 0 {
            indexBuffer = device.makeBuffer(
                bytes: elementBuffer.data,
                length: elementBuffer.length,
                options: []
            )
            if let indexBuffer = indexBuffer {
                indexBuffer.label = "\(label) Indices"
                elementBuffer.needsUpdate = false
            }
        }
        else {
            indexBuffer = nil
            elementBuffer.needsUpdate = false
        }
    }
}
