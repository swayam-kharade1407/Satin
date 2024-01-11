//
//  RenderEncoderState.swift
//
//
//  Created by Reza Ali on 12/12/23.
//

import Foundation
import Metal

public class RenderEncoderState {
    public let renderEncoder: MTLRenderCommandEncoder

    public var cullMode: MTLCullMode? {
        didSet {
            if oldValue != cullMode, let cullMode {
                renderEncoder.setCullMode(cullMode)
            }
        }
    }

    public var windingOrder: MTLWinding? {
        didSet {
            if oldValue != windingOrder, let windingOrder {
                renderEncoder.setFrontFacing(windingOrder)
            }
        }
    }

    public var triangleFillMode: MTLTriangleFillMode? {
        didSet {
            if oldValue != triangleFillMode, let triangleFillMode {
                renderEncoder.setTriangleFillMode(triangleFillMode)
            }
        }
    }

    public var pipeline: MTLRenderPipelineState? {
        didSet {
            if oldValue !== pipeline, let pipeline {
                renderEncoder.setRenderPipelineState(pipeline)
            }
        }
    }

    public var depthStencilState: MTLDepthStencilState? {
        didSet {
            if oldValue !== depthStencilState {
                renderEncoder.setDepthStencilState(depthStencilState)
            }
        }
    }

    public var depthClipMode: MTLDepthClipMode? {
        didSet {
            if oldValue != depthClipMode, let depthClipMode {
                #if os(macOS) || os(iOS) || os(tvOS)
                renderEncoder.setDepthClipMode(depthClipMode)
                #endif
            }
        }
    }

    public var depthBias: DepthBias? {
        didSet {
            if oldValue != depthBias {
                if let depthBias = depthBias {
                    renderEncoder.setDepthBias(depthBias.bias, slopeScale: depthBias.slope, clamp: depthBias.clamp)
                }
                else {
                    renderEncoder.setDepthBias(0.0, slopeScale: 0.0, clamp: 0.0)
                }
            }
        }
    }

    public var vertexUniforms: VertexUniformBuffer? {
        didSet {
            if oldValue !== vertexUniforms, let vertexUniforms {
                renderEncoder.setVertexBuffer(
                    vertexUniforms.buffer,
                    offset: vertexUniforms.offset,
                    index: VertexBufferIndex.VertexUniforms.rawValue
                )
            }
        }
    }

    public var vertexMaterialUniforms: UniformBuffer? {
        didSet {
            if oldValue !== vertexMaterialUniforms, let vertexMaterialUniforms {
                renderEncoder.setVertexBuffer(
                    vertexMaterialUniforms.buffer,
                    offset: vertexMaterialUniforms.offset,
                    index: VertexBufferIndex.MaterialUniforms.rawValue
                )
            }
        }
    }

    public var vertexInstanceUniforms: InstanceMatrixUniformBuffer? {
        didSet {
            if oldValue !== vertexInstanceUniforms, let vertexInstanceUniforms {
                renderEncoder.setVertexBuffer(
                    vertexInstanceUniforms.buffer,
                    offset: vertexInstanceUniforms.offset,
                    index: VertexBufferIndex.InstanceMatrixUniforms.rawValue
                )
            }
        }
    }

    public var fragmentMaterialUniforms: UniformBuffer? {
        didSet {
            if oldValue !== fragmentMaterialUniforms, let fragmentMaterialUniforms {
                renderEncoder.setFragmentBuffer(
                    fragmentMaterialUniforms.buffer,
                    offset: fragmentMaterialUniforms.offset,
                    index: FragmentBufferIndex.MaterialUniforms.rawValue
                )
            }
        }
    }

    private var vertexBuffers = [VertexBufferIndex: MTLBuffer]()
    private var vertexTextures = [VertexTextureIndex: MTLTexture?]()

    private var fragmentPBRTextures = [PBRTextureType: MTLTexture?]()
    private var fragmentTextures = [FragmentTextureIndex: MTLTexture?]()

    public func setVertexBuffer(_ buffer: MTLBuffer, offset: Int, index: VertexBufferIndex) {
        if let existingBuffer = vertexBuffers[index], existingBuffer === buffer {
            return
        }
        else {
            renderEncoder.setVertexBuffer(buffer, offset: offset, index: index.rawValue)
            vertexBuffers[index] = buffer
        }
    }

    public func setFragmentPBRTexture(_ texture: MTLTexture?, type: PBRTextureType) {
        if let existingTexture = fragmentPBRTextures[type], existingTexture === texture {
            return
        }
        else {
            renderEncoder.setFragmentTexture(texture, index: type.index)
            fragmentPBRTextures[type] = texture
        }
    }

    public func setVertexTexture(_ texture: MTLTexture?, index: VertexTextureIndex) {
        if let existingTexture = vertexTextures[index], existingTexture === texture {
            return
        }
        else {
            renderEncoder.setVertexTexture(texture, index: index.rawValue)
            vertexTextures[index] = texture
        }
    }

    public func setFragmentTexture(_ texture: MTLTexture?, index: FragmentTextureIndex) {
        if let existingTexture = fragmentTextures[index], existingTexture === texture {
            return
        }
        else {
            renderEncoder.setFragmentTexture(texture, index: index.rawValue)
            fragmentTextures[index] = texture
        }
    }

    init(renderEncoder: MTLRenderCommandEncoder) {
        self.renderEncoder = renderEncoder
    }
}
