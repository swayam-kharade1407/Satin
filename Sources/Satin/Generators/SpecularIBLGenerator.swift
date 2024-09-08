//
//  SpecularIBLGenerator.swift
//  Satin
//
//  Created by Reza Ali on 11/8/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import Metal

public final class SpecularIBLGenerator {
    final class SpecularIBLComputeProcessor: TextureComputeProcessor {
        init(device: MTLDevice) {
            super.init(
                device: device,
                pipelinesURL: getPipelinesComputeURL()!
            )
        }

        override func getSize(texture: MTLTexture, iteration: Int) -> MTLSize {
            let level = iteration / 6
            let size = Int(Float(texture.width) / pow(2.0, Float(level)))
            return MTLSize(width: size, height: size, depth: texture.depth)
        }
    }

    private var compute: SpecularIBLComputeProcessor

    public init(device: MTLDevice) {
        compute = SpecularIBLComputeProcessor(device: device)
    }

    public func encode(commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        let levels = destinationTexture.mipmapLevelCount
        let width = destinationTexture.width
        
        compute.set(destinationTexture, index: ComputeTextureIndex.Custom0) // output
        compute.set(sourceTexture, index: ComputeTextureIndex.Custom1) // input

        compute.preCompute = { computeEncoder, iteration in
            var face = UInt32(iteration % 6)
            var level = UInt32(iteration/6)
            var size = UInt32(Float(width) / pow(2.0, Float(level)))
            var roughness = Float(level) / Float(levels - 1)
            computeEncoder.setBytes(&face, length: MemoryLayout<UInt32>.size, index: ComputeBufferIndex.Custom0.rawValue)
            computeEncoder.setBytes(&level, length: MemoryLayout<UInt32>.size, index: ComputeBufferIndex.Custom1.rawValue)
            computeEncoder.setBytes(&size, length: MemoryLayout<UInt32>.size, index: ComputeBufferIndex.Custom2.rawValue)
            computeEncoder.setBytes(&roughness, length: MemoryLayout<Float>.size, index: ComputeBufferIndex.Custom3.rawValue)
        }

        commandBuffer.label = "\(compute.label) Compute Command Buffer"
        compute.update(commandBuffer, iterations: 6 * levels)

        destinationTexture.label = "Specular IBL"
    }
}
