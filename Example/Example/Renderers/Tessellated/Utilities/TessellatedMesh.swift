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

    func isDrawable(renderContext: Context, shadow: Bool) -> Bool {
        guard let material,
              material.getPipeline(renderContext: renderContext, shadow: shadow) != nil,
              geometry.vertexBuffers[.Vertices] != nil,
              vertexUniforms[renderContext] != nil
        else { return false }
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

    var vertexUniforms: [Context: VertexUniformBuffer] = [:]
    var geometry: TessellatedGeometry
    var tessellator: Tessellator

    public init(geometry: TessellatedGeometry, material: Material?, tessellator: Tessellator) {
        self.geometry = geometry
        self.material = material
        self.tessellator = tessellator
        super.init(label: "Tessellated Mesh")
    }

    override func setup() {
        setupVertexUniforms()
        setupGeometry()
        setupMaterial()
        super.setup()
    }

    override func update() {
        geometry.update()
        material?.update()
        super.update()
    }

    func setupVertexUniforms() {
        guard let context, vertexUniforms[context] == nil else { return }
        vertexUniforms[context] = VertexUniformBuffer(context: context)
    }

    func setupGeometry() {
        guard let context else { return }
        geometry.context = context
    }

    func setupMaterial() {
        guard let context, let material else { return }
        material.vertexDescriptor = geometry.vertexDescriptor
        material.context = context
    }

    // MARK: - Update

    override func encode(_ commandBuffer: MTLCommandBuffer) {
        material?.encode(commandBuffer)
        geometry.encode(commandBuffer)
        super.encode(commandBuffer)
    }

    override func update(renderContext: Context, camera: Camera, viewport: simd_float4, index: Int) {
        vertexUniforms[renderContext]?.update(
            object: self,
            camera: camera,
            viewport: viewport,
            index: index
        )

        super.update(
            renderContext: renderContext,
            camera: camera,
            viewport: viewport,
            index: index
        )
    }

    // MARK: - Draw

    open func draw(renderContext: Context, renderEncoderState: RenderEncoderState, instanceCount: Int, shadow: Bool) {
        guard instanceCount > 0, let vertexUniforms = vertexUniforms[renderContext], let material, !geometry.vertexBuffers.isEmpty else { return }

        renderEncoderState.vertexVertexUniforms = vertexUniforms
        geometry.bind(renderEncoderState: renderEncoderState, shadow: shadow)
        material.bind(renderContext: renderContext, renderEncoderState: renderEncoderState, shadow: shadow)

        let renderEncoder = renderEncoderState.renderEncoder

        renderEncoder.setTessellationFactorBuffer(
            tessellator.buffer,
            offset: 0,
            instanceStride: 0
        )

        geometry.draw(renderEncoderState: renderEncoderState, instanceCount: instanceCount)
    }

    func draw(renderContext: Context, renderEncoderState: RenderEncoderState, shadow: Bool) {
        draw(
            renderContext: renderContext,
            renderEncoderState: renderEncoderState,
            instanceCount: 1,
            shadow: shadow
        )
    }

    func getVertexUniformBuffer(renderContext: Context) -> VertexUniformBuffer? {
        vertexUniforms[renderContext]
    }
}
