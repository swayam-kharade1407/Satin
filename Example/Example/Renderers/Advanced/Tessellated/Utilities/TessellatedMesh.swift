//
//  TessellatedMesh.swift
//  Tesselation
//
//  Created by Reza Ali on 3/31/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import simd

import Satin

class TessellatedMesh: Object, Renderable {
    var preDraw: ((MTLRenderCommandEncoder) -> Void)?
    
    var opaque: Bool {
        material?.blending == .disabled
    }

    var doubleSided: Bool = false

    var cullMode: MTLCullMode = .back
    var windingOrder: MTLWinding = .counterClockwise
    var triangleFillMode: MTLTriangleFillMode = .fill

    var renderOrder = 0
    var renderPass = 0

    var lighting: Bool { material?.lighting ?? false }
    var receiveShadow: Bool { material?.receiveShadow ?? false }
    var castShadow: Bool { material?.castShadow ?? false }

    private var vertexUniforms: VertexUniformBuffer?

    var drawable: Bool {
        guard material?.pipeline != nil, geometry.vertexBuffers[.Vertices] != nil else { return false }
        return true
    }

    var material: Satin.Material? {
        didSet {
            material?.context = context
        }
    }

    var materials: [Satin.Material] {
        if let material = material {
            return [material]
        }
        return []
    }

    public required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    var geometry: TessellatedGeometry
    var tessellator: Tessellator

    public init(geometry: TessellatedGeometry, material: Material?, tessellator: Tessellator) {
        self.geometry = geometry
        self.material = material
        self.tessellator = tessellator
        super.init(label: "Tessellated Mesh")
    }

    override func setup() {
        setupGeometry()
        setupUniforms()
        setupMaterial()
        super.setup()
    }

    override func update() {
        geometry.update()
        material?.update()
        super.update()
    }

    func setupGeometry() {
        guard let context = context else { return }
        geometry.context = context
    }

    func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.vertexDescriptor = geometry.vertexDescriptor
        material.context = context
    }

    func setupUniforms() {
        guard let context = context else { return }
        vertexUniforms = VertexUniformBuffer(device: context.device)
    }

    // MARK: - Update

    override func encode(_ commandBuffer: MTLCommandBuffer) {
        material?.encode(commandBuffer)
        geometry.encode(commandBuffer)
        super.encode(commandBuffer)
    }

    override func update(camera: Camera, viewport: simd_float4) {
        material?.update(camera: camera, viewport: viewport)
        geometry.update(camera: camera, viewport: viewport)
        vertexUniforms?.update(object: self, camera: camera, viewport: viewport)
        super.update(camera: camera, viewport: viewport)
    }

    // MARK: - Draw

    open func draw(renderEncoderState: RenderEncoderState, instanceCount: Int, shadow: Bool) {
        guard instanceCount > 0, let vertexUniforms = vertexUniforms, let material = material, !geometry.vertexBuffers.isEmpty else { return }

        renderEncoderState.vertexUniforms = vertexUniforms
        geometry.bind(renderEncoderState: renderEncoderState, shadow: shadow)
        material.bind(renderEncoderState: renderEncoderState, shadow: shadow)

        let renderEncoder = renderEncoderState.renderEncoder

        renderEncoder.setTessellationFactorBuffer(
            tessellator.buffer,
            offset: 0,
            instanceStride: 0
        )

        geometry.draw(renderEncoderState: renderEncoderState, instanceCount: instanceCount)
    }

    func draw(renderEncoderState: RenderEncoderState, shadow: Bool) {
        draw(renderEncoderState: renderEncoderState, instanceCount: 1, shadow: shadow)
    }
}
