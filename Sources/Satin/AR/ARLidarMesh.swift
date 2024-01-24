//
//  ARLidarMesh.swift
//  Example
//
//  Created by Reza Ali on 4/10/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Metal

public func ARLidarMeshVertexDescriptor() -> MTLVertexDescriptor {
    // position
    let vertexDescriptor = MTLVertexDescriptor()

    vertexDescriptor.attributes[0].format = MTLVertexFormat.float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0

    vertexDescriptor.layouts[0].stride = MemoryLayout<MTLPackedFloat3>.stride
    vertexDescriptor.layouts[0].stepRate = 1
    vertexDescriptor.layouts[0].stepFunction = .perVertex

    return vertexDescriptor
}

public class ARLidarMesh: Object, Renderable {
    public var preDraw: ((MTLRenderCommandEncoder) -> Void)?

    public var opaque: Bool { material?.blending == .disabled }
    public var doubleSided: Bool = false

    public var lighting: Bool { material?.lighting ?? false }
    public var receiveShadow: Bool { false }
    public var castShadow: Bool { false }

    public var renderOrder = 0
    public var renderPass = 0

    public var drawable: Bool {
        if material?.pipeline != nil, uniforms != nil, vertexBuffer != nil, indexBuffer != nil {
            return true
        }
        return false
    }

    var uniforms: VertexUniformBuffer?

    public var material: Material?
    public var materials: [Satin.Material] {
        if let material = material {
            return [material]
        } else {
            return []
        }
    }

    public var cullMode: MTLCullMode = .back
    public var windingOrder: MTLWinding = .counterClockwise
    public var triangleFillMode: MTLTriangleFillMode = .fill

    public var indexBuffer: MTLBuffer? {
        meshAnchor?.geometry.faces.buffer ?? nil
    }

    public var indexCount: Int {
        (meshAnchor?.geometry.faces.count ?? 0) * 3
    }

    public var vertexBuffer: MTLBuffer? {
        meshAnchor?.geometry.vertices.buffer ?? nil
    }

    public var vertexCount: Int {
        meshAnchor?.geometry.vertices.count ?? 0
    }

    public var normalBuffer: MTLBuffer? {
        meshAnchor?.geometry.normals.buffer ?? nil
    }

    public var normalCount: Int {
        meshAnchor?.geometry.normals.count ?? 0
    }

    public var meshAnchor: ARMeshAnchor?

    public init(meshAnchor: ARMeshAnchor, material: Material) {
        self.meshAnchor = meshAnchor
        self.material = material
        material.vertexDescriptor = ARLidarMeshVertexDescriptor()
        super.init(label: "Lidar Mesh \(meshAnchor.identifier)")
    }

    override public func setup() {
        setupUniforms()
        setupMaterial()
    }

    func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.context = context
    }

    func setupUniforms() {
        guard let context = context else { return }
        uniforms = VertexUniformBuffer(device: context.device)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    // MARK: - Update

    override public func encode(_ commandBuffer: MTLCommandBuffer) {
        material?.encode(commandBuffer)
        super.encode(commandBuffer)
    }

    override public func update(camera: Camera, viewport: simd_float4) {
        if let meshAnchor = meshAnchor { localMatrix = meshAnchor.transform }
        material?.update(camera: camera, viewport: viewport)
        uniforms?.update(object: self, camera: camera, viewport: viewport)
        super.update(camera: camera, viewport: viewport)
    }

    // MARK: - Draw

    public func draw(renderEncoderState: RenderEncoderState, shadow: Bool) {
        guard let uniforms = uniforms,
              let vertexBuffer = vertexBuffer,
              let material = material,
              let _ = material.pipeline
        else { return }

        renderEncoderState.vertexUniforms = uniforms
        renderEncoderState.setVertexBuffer(vertexBuffer, offset: 0, index: .Vertices)
        material.bind(renderEncoderState: renderEncoderState, shadow: shadow)

        let renderEncoder = renderEncoderState.renderEncoder

        if let indexBuffer = indexBuffer {
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: indexCount,
                indexType: .uint32,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0,
                instanceCount: 1
            )
        } else {
            renderEncoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: vertexCount,
                instanceCount: 1
            )
        }
    }
}

#endif
