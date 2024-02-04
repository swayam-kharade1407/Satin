//
//  RayMarchingRenderer.swift
//  Example
//
//  Created by Reza Ali on 6/26/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Satin

class RayMarchingRenderer: BaseRenderer {
    class RayMarchedMaterial: SourceMaterial {
        var camera: PerspectiveCamera?

        init(pipelinesURL: URL, camera: PerspectiveCamera?) {
            self.camera = camera
            super.init(pipelinesURL: pipelinesURL)
            blending = .disabled
        }

        required init() {
            fatalError("init() has not been implemented")
        }

        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }

        override func bind(renderEncoderState: RenderEncoderState, shadow: Bool) {
            super.bind(renderEncoderState: renderEncoderState, shadow: shadow)
            if let camera = camera {
                var view = camera.viewMatrix
                renderEncoderState.renderEncoder.setFragmentBytes(&view, length: MemoryLayout<float4x4>.size, index: FragmentBufferIndex.Custom0.rawValue)
            }
        }
    }

    var mesh = Mesh(geometry: BoxGeometry(size: 2.0), material: BasicDiffuseMaterial(0.7))
    var camera = PerspectiveCamera(position: [0.0, 0.0, 5.0], near: 0.001, far: 100.0, fov: 45)

    lazy var rayMarchedMaterial = RayMarchedMaterial(pipelinesURL: pipelinesURL, camera: camera)
    lazy var rayMarchedMesh = Mesh(geometry: QuadGeometry(), material: rayMarchedMaterial)
    lazy var scene = Object(label: "Scene", [mesh, rayMarchedMesh])
    lazy var context = Context(device: device, sampleCount: sampleCount, colorPixelFormat: colorPixelFormat, depthPixelFormat: depthPixelFormat, stencilPixelFormat: stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: metalView)
    lazy var renderer = Renderer(context: context)

    deinit {
        cameraController.disable()
    }

    override func update() {
        cameraController.update()
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
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }
}
