//
//  IBLScene.swift
//
//
//  Created by Reza Ali on 3/11/23.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

public final class IBLScene: Object, IBLEnvironment {
    public var environmentIntensity: Float = 1.0

    public internal(set) var environment: MTLTexture?
    public internal(set) var cubemapTexture: MTLTexture?
    public internal(set) var brdfTexture: MTLTexture?

    public internal(set) var irradianceTexture: MTLTexture?
    public var irradianceTexcoordTransform = matrix_identity_float3x3

    public internal(set) var reflectionTexture: MTLTexture?
    public var reflectionTexcoordTransform = matrix_identity_float3x3

    static let cubemapGenerator = CubemapGenerator(device: MTLCreateSystemDefaultDevice()!) // 0.023512959480285645
    static let diffuseIBLGenerator = DiffuseIBLGenerator(device: MTLCreateSystemDefaultDevice()!) // 0.3512990474700928
    static let specularIBLGenerator = SpecularIBLGenerator(device: MTLCreateSystemDefaultDevice()!) // 0.09427797794342041
    static let brdfGenerator = BrdfGenerator(device: MTLCreateSystemDefaultDevice()!, size: 512) // 0.012279033660888672

    private var qos: DispatchQoS.QoSClass = .userInitiated
    private var cubemapSize: Int = 512
    private var reflectionSize: Int = 512
    private var irradianceSize: Int = 64

    public func setEnvironment(texture: MTLTexture, qos: DispatchQoS.QoSClass = .userInitiated, cubemapSize: Int = 512, reflectionSize: Int = 512, irradianceSize: Int = 64) {
        environment = texture
        self.cubemapSize = cubemapSize
        self.reflectionSize = reflectionSize
        self.irradianceSize = irradianceSize

        DispatchQueue.global(qos: qos).async { [unowned self] in
            guard let environment = self.environment,
                  let commandQueue = environment.device.makeCommandQueue(),
                  let commandBuffer = commandQueue.makeCommandBuffer() else { return }

            let device = environment.device

            self.cubemapTexture = self.setupCubemapTexture(device: device, commandBuffer: commandBuffer)
            self.irradianceTexture = self.setupIrradianceTexture(device: device, commandBuffer: commandBuffer)
            self.reflectionTexture = self.setupReflectionTexture(device: device, commandBuffer: commandBuffer)

            if self.brdfTexture == nil {
                self.brdfTexture = self.setupBrdfTexture(device: device, commandBuffer: commandBuffer)
            }

            commandBuffer.commit()
        }
    }

    public func setEnvironmentCubemap(texture: MTLTexture, qos: DispatchQoS.QoSClass = .userInitiated, reflectionSize: Int = 512, irradianceSize: Int = 32) {
        cubemapTexture = texture
        cubemapSize = texture.width
        self.reflectionSize = reflectionSize
        self.irradianceSize = irradianceSize

        let device = texture.device

        DispatchQueue.global(qos: qos).async { [unowned self] in
            guard let commandQueue = texture.device.makeCommandQueue(),
                  let commandBuffer = commandQueue.makeCommandBuffer() else { return }

            self.irradianceTexture = self.setupIrradianceTexture(device: device, commandBuffer: commandBuffer)
            self.reflectionTexture = self.setupReflectionTexture(device: device, commandBuffer: commandBuffer)
            if self.brdfTexture == nil {
                self.brdfTexture = self.setupBrdfTexture(device: device, commandBuffer: commandBuffer)
            }

            commandBuffer.commit()
        }
    }

    private func setupCubemapTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        if let hdriTexture = environment,
           let texture = createCubemapTexture(
               device: device,
               pixelFormat: .rgba16Float,
               size: cubemapSize,
               mipmapped: true
           )
        {
            IBLScene.cubemapGenerator
                .encode(
                    commandBuffer: commandBuffer,
                    sourceTexture: hdriTexture,
                    destinationTexture: texture
                )
            return texture
        }
        return nil
    }

    private func setupIrradianceTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        if let cubemapTexture = cubemapTexture,
           let texture = createCubemapTexture(
               device: device,
               pixelFormat: .rgba16Float,
               size: irradianceSize,
               mipmapped: false
           )
        {
            IBLScene.diffuseIBLGenerator
                .encode(
                    commandBuffer: commandBuffer,
                    sourceTexture: cubemapTexture,
                    destinationTexture: texture
                )
            return texture
        }
        return nil
    }

    private func setupReflectionTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        if let cubemapTexture = cubemapTexture,
           let texture = createCubemapTexture(
               device: device,
               pixelFormat: .rgba16Float,
               size: reflectionSize,
               mipmapped: true
           )
        {
            IBLScene.specularIBLGenerator
                .encode(
                    commandBuffer: commandBuffer,
                    sourceTexture: cubemapTexture,
                    destinationTexture: texture
                )
            return texture
        }
        return nil
    }

    private func setupBrdfTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        IBLScene.brdfGenerator.encode(commandBuffer: commandBuffer)
    }

    private func createCubemapTexture(device: MTLDevice, pixelFormat: MTLPixelFormat, size: Int, mipmapped: Bool) -> MTLTexture?
    {
        let desc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: pixelFormat, size: size, mipmapped: mipmapped)
        desc.usage = [.shaderWrite, .shaderRead]
        desc.allowGPUOptimizedContents = true
        desc.storageMode = .private
        desc.resourceOptions = .storageModePrivate

        return device.makeTexture(descriptor: desc)
    }
}
