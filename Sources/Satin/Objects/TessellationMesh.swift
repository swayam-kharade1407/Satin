//
//  TessellationMesh.swift
//  Satin
//
//  Created by Reza Ali on 3/31/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import simd

final public class TessellationMesh: Mesh {
    var tessellator: Tessellator
    var tessellate: Bool

    public init(label: String, geometry: TessellationGeometry, material: Material?, tessellator: Tessellator, tessellate: Bool = true) {
        self.tessellator = tessellator
        self.tessellate = tessellate
        super.init(
            label: label,
            geometry: geometry,
            material: material
        )
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    public override func encode(_ commandBuffer: any MTLCommandBuffer) {
        if tessellate {
            tessellator.update(commandBuffer, iterations: 1)
        }
        super.encode(commandBuffer)
    }
    // MARK: - Draw

    public override func draw(renderContext: Context, renderEncoderState: RenderEncoderState, instanceCount: Int, shadow: Bool) {
        guard instanceCount > 0, let vertexUniforms = vertexUniforms[renderContext], let material, !geometry.vertexBuffers.isEmpty else { return }

        renderEncoderState.vertexVertexUniforms = vertexUniforms

        geometry.bind(
            renderEncoderState: renderEncoderState,
            shadow: shadow
        )

        material.bind(
            renderContext: renderContext,
            renderEncoderState: renderEncoderState,
            shadow: shadow
        )

        let renderEncoder = renderEncoderState.renderEncoder

        renderEncoder.setTessellationFactorBuffer(
            tessellator.factorsBuffer,
            offset: 0,
            instanceStride: 0
        )

        geometry.draw(renderEncoderState: renderEncoderState, instanceCount: instanceCount)
    }
}
