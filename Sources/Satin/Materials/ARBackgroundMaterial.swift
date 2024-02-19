//
//  ARBackgroundMaterial.swift
//
//
//  Created by Reza Ali on 1/23/24.
//

#if os(iOS)

import ARKit
import Metal

public final class ARBackgroundMaterial: Material {
    public var color: simd_float4 {
        set {
            (get("Color") as! Float4Parameter).value = newValue
        }
        get {
            (get("Color") as! Float4Parameter).value
        }
    }

    public var srgb: Bool {
        set {
            (get("Srgb") as! BoolParameter).value = newValue
        }
        get {
            (get("Srgb") as! BoolParameter).value
        }
    }

    public var capturedImageTextureY: CVMetalTexture?
    public var capturedImageTextureCbCr: CVMetalTexture?

    public init(color: simd_float4 = simd_float4(repeating: 1.0), srgb: Bool = false) {
        super.init()
        set("Color", color)
        set("Srgb", srgb)
        configure()
    }

    public required init() {
        super.init()
        set("Color", simd_float4.one)
        set("Srgb", false)
        configure()
    }

    internal func configure() {
        depthWriteEnabled = false
        depthCompareFunction = .always
        blending = .alpha
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    public override func bind(renderEncoderState: RenderEncoderState, shadow: Bool) {
        super.bind(renderEncoderState: renderEncoderState, shadow: shadow)

        if let textureY = capturedImageTextureY, let textureCbCr = capturedImageTextureCbCr {
            renderEncoderState.setFragmentTexture(CVMetalTextureGetTexture(textureY), index: .Custom0)
            renderEncoderState.setFragmentTexture(CVMetalTextureGetTexture(textureCbCr), index: .Custom1)
        }
    }
}

#endif
