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
    final class RayMarchedMaterial: SourceMaterial {
        init(pipelinesURL: URL) {
            super.init(pipelinesURL: pipelinesURL, live: true)
            blending = .disabled
        }

        required init() {
            fatalError("init() has not been implemented")
        }

        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }

    var mesh = Mesh(geometry: BoxGeometry(size: 2.0), material: BasicDiffuseMaterial(hardness: 0.7))
    var camera = {
        let c = PerspectiveCamera(position: [10.0, 10.0, 10.0], near: 0.1, far: 100.0, fov: 45)
        c.lookAt(target: .zero)
        return c
    }()

    lazy var rayMarchedMaterial = RayMarchedMaterial(pipelinesURL: pipelinesURL)
    lazy var rayMarchedMesh = Mesh(geometry: QuadGeometry(), material: rayMarchedMaterial)
    lazy var scene = Object(label: "Scene", [mesh, rayMarchedMesh])
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: metalView)
    lazy var renderer = Renderer(context: defaultContext)

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
