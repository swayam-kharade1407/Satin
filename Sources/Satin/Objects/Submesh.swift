//
//  Submesh.swift
//  Satin
//
//  Created by Reza Ali on 5/25/20.
//

import Combine
import Metal

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
    public var indexCount: Int {
        return indexData.count
    }

    public var offset = 0
    public var indexType: MTLIndexType = .uint32
    public var indexBuffer: MTLBuffer?
    public var indexData: [UInt32] = [] {
        didSet {
            if context != nil {
                setup()
            }
        }
    }

    weak var parent: Mesh?
    var material: Material?

    public init(
        label: String = "Submesh",
        parent: Mesh,
        indexData: [UInt32],
        indexBuffer: MTLBuffer? = nil,
        offset: Int = 0,
        material: Material? = nil
    ) {
        self.parent = parent
        self.indexData = indexData
        self.indexBuffer = indexBuffer
        self.offset = offset
        self.material = material
    }

    private func setup() {
        if indexBuffer == nil {
            setupIndexBuffer()
        }
        setupMaterial()
    }

    func encode(_ commandBuffer: MTLCommandBuffer) {
        material?.encode(commandBuffer)
    }

    private func setupMaterial() {
        guard let context = context, let material = material, let parent = parent else { return }
        material.vertexDescriptor = parent.geometry.vertexDescriptor
        material.context = context
    }

    private func setupIndexBuffer() {
        guard let context = context else { return }
        let device = context.device
        if !indexData.isEmpty {
            let indicesSize = indexData.count * MemoryLayout.size(ofValue: indexData[0])
            indexBuffer = device.makeBuffer(bytes: indexData, length: indicesSize, options: [])
            indexBuffer?.label = "Indices"
        } else {
            indexBuffer = nil
        }
    }
}
