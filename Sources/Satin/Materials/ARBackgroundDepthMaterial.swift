//
//  ARBackgroundDepthMaterial.swift
//
//
//  Created by Reza Ali on 1/24/24.
//

#if os(iOS)

import ARKit
import Metal

public class ARBackgroundDepthMaterial: Material {
    public var upscaledSceneDepthTexture: MTLTexture?
    public var sceneDepthTexture: CVMetalTexture?

    public required init() {
        super.init()
        configure()
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        configure()
    }

    private func configure() {
        depthWriteEnabled = true
        blending = .alpha
    }

    override public func bind(renderEncoderState: RenderEncoderState, shadow: Bool) {
        super.bind(renderEncoderState: renderEncoderState, shadow: shadow)

        if let upscaledSceneDepthTexture = upscaledSceneDepthTexture {
            renderEncoderState.setFragmentTexture(upscaledSceneDepthTexture, index: .Custom0)
        }
        else if let sceneDepthTexture = sceneDepthTexture {
            renderEncoderState.setFragmentTexture(CVMetalTextureGetTexture(sceneDepthTexture), index: .Custom0)
        }
    }
}

#endif
