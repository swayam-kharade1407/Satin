//
//  Renderer.swift
//  AudioInput-macOS
//
//  Created by Reza Ali on 8/4/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

#if !os(visionOS)

import Metal
import MetalKit

import Satin

class AudioInputRenderer: BaseRenderer {
    lazy var audioInput: AudioInput = .init(context: context)

    lazy var audioMaterial: BasicTextureMaterial = {
        let mat = BasicTextureMaterial()

        let desc = MTLSamplerDescriptor()
        desc.label = "Audio Texture Sampler"
        desc.minFilter = .nearest
        desc.magFilter = .nearest
        mat.sampler = context.device.makeSamplerState(descriptor: desc)

        mat.onUpdate = { [weak self, weak mat] in
            guard let self = self, let mat = mat else { return }
            mat.texture = self.audioInput.texture
        }
        return mat
    }()

    lazy var mesh: Mesh = .init(geometry: PlaneGeometry(size: 700), material: audioMaterial)

    var camera = OrthographicCamera()

    lazy var scene = Object(label: "Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
//    lazy var cameraController = OrthographicCameraController(camera: camera, view: metalView)
    lazy var renderer = Renderer(context: context)

    override var depthPixelFormat: MTLPixelFormat {
        .invalid
    }

    override func setup() {
        print(audioInput.inputs)
    }

    override func update() {
//        cameraController.update()
        camera.update()
        scene.update()
    }

    override func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    override func resize(size: (width: Float, height: Float), scaleFactor: Float) {
//        cameraController.resize(size)
        renderer.resize(size)
    }
}

#endif
