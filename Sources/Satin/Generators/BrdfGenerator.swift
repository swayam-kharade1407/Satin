//
//  BrdfGenerator.swift
//  Satin
//
//  Created by Reza Ali on 11/8/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import Metal

public final class BrdfGenerator {
    final class BrdfComputeSystem: TextureComputeSystem {
        init(device: MTLDevice, textureDescriptor: MTLTextureDescriptor) {
            super.init(
                device: device,
                pipelinesURL: getPipelinesComputeURL()!,
                textureDescriptors: [textureDescriptor]
            )
        }
    }

    private var compute: BrdfComputeSystem

    public init(device: MTLDevice, size: Int) {
        let textureDescriptor: MTLTextureDescriptor = .texture2DDescriptor(
            pixelFormat: .rg16Float,
            width: size,
            height: size,
            mipmapped: false
        )
        compute = BrdfComputeSystem(device: device, textureDescriptor: textureDescriptor)
    }

    public func encode(commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        commandBuffer.label = "\(compute.label) Compute Command Buffer"
        compute.update(commandBuffer)
        let texture = compute.dstTextures[0]
        texture.label = "BRDF LUT"
        return texture
    }
}
