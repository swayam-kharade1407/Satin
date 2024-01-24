//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 6/11/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Satin

class TextureComputeRenderer: BaseRenderer {
    class BasicTextureComputeSystem: TextureComputeSystem {}

    lazy var textureCompute: BasicTextureComputeSystem = {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.width = 512
        textureDescriptor.height = 512
        textureDescriptor.depth = 1
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.resourceOptions = .storageModePrivate
        textureDescriptor.sampleCount = 1
        textureDescriptor.textureType = .type2D
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        return BasicTextureComputeSystem(
            device: device,
            pipelinesURL: pipelinesURL,
            textureDescriptors: [textureDescriptor],
            live: true
        )
    }()

    var material = BasicTextureMaterial(texture: nil)
    lazy var mesh = Mesh(geometry: BoxGeometry(), material: material)

    lazy var scene = Object(label: "Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)

    lazy var camera = PerspectiveCamera(position: [0.0, 0.0, 9.0], near: 0.001, far: 100.0)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: metalView)
    lazy var renderer = Renderer(context: context)

    lazy var startTime: CFAbsoluteTime = getTime()

    override func setup() {
        material.texture = textureCompute.dstTexture
    }

    deinit {
        cameraController.disable()
    }
    
    override func update() {
        material.texture = textureCompute.dstTexture
        cameraController.update()
        textureCompute.set("Time", Float(getTime() - startTime))
        camera.update()
        scene.update()
    }

    override func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        textureCompute.update(commandBuffer)
        
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    override func resize(size: (width: Float, height: Float), scaleFactor: Float) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }

    func getTime() -> CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent()
    }
}
