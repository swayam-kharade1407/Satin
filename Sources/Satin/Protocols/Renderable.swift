//
//  Renderable.swift
//
//
//  Created by Reza Ali on 4/19/22.
//

import Foundation
import Metal
import simd

public protocol Renderable {
    var label: String { get }
    
    var opaque: Bool { get }
    var doubleSided: Bool { get }

    var renderOrder: Int { get }
    var renderPass: Int { get }

    var lighting: Bool { get }
    var receiveShadow: Bool { get }
    var castShadow: Bool { get }

    var cullMode: MTLCullMode { get }
    var windingOrder: MTLWinding { get }
    var triangleFillMode: MTLTriangleFillMode { get }

    var vertexUniforms: [Context: VertexUniformBuffer] { get }
    func isDrawable(renderContext: Context) -> Bool

    var material: Material? { get set }
    var materials: [Material] { get }

    func update(renderContext: Context, camera: Camera, viewport: simd_float4, index: Int)

    var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> Void)? { get }
    func draw(renderContext: Context, renderEncoderState: RenderEncoderState, shadow: Bool)
}
