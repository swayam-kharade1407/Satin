//
//  VertexUniformBuffer.swift
//  Satin
//
//  Created by Reza Ali on 4/21/22.
//

import Metal
import simd

public final class VertexUniformBuffer {
    public private(set) var context: Context
    public private(set) var buffer: MTLBuffer
    public private(set) var offset = 0

    private var offsetIndex: Int = -1
    private var uniforms: UnsafeMutablePointer<VertexUniforms>!
    private let alignedSize = ((MemoryLayout<VertexUniforms>.size + 255) / 256) * 256

    public init(context: Context) {
        self.context = context
        let length = alignedSize * Satin.maxBuffersInFlight * context.vertexAmplificationCount
        guard let buffer = context.device.makeBuffer(length: length, options: [MTLResourceOptions.cpuCacheModeWriteCombined]) else { fatalError("Couldn't not create Vertex Uniform Buffer") }
        self.buffer = buffer
        self.buffer.label = "Vertex Uniforms"
    }

    public func update(object: Object, camera: Camera, viewport: simd_float4, index: Int) {
        offsetIndex = (offsetIndex + 1) % maxBuffersInFlight
        offset = alignedSize * (offsetIndex * context.vertexAmplificationCount)

        uniforms = UnsafeMutableRawPointer(buffer.contents() + offset).bindMemory(to: VertexUniforms.self, capacity: context.vertexAmplificationCount)

        uniforms[index].modelMatrix = object.worldMatrix
        uniforms[index].viewMatrix = camera.viewMatrix
        uniforms[index].modelViewMatrix = simd_mul(uniforms[index].viewMatrix, uniforms[index].modelMatrix)
        uniforms[index].projectionMatrix = camera.projectionMatrix
        uniforms[index].viewProjectionMatrix = camera.viewProjectionMatrix
        uniforms[index].modelViewProjectionMatrix = simd_mul(camera.viewProjectionMatrix, uniforms[index].modelMatrix)
        uniforms[index].inverseModelViewProjectionMatrix = simd_inverse(uniforms[index].modelViewProjectionMatrix)
        uniforms[index].inverseViewMatrix = camera.worldMatrix
        uniforms[index].normalMatrix = object.normalMatrix
        uniforms[index].viewport = viewport
        uniforms[index].worldCameraPosition = camera.worldPosition
        uniforms[index].worldCameraViewDirection = camera.viewDirection
    }
}
