//
//  Renderer.swift
//  LiveCode-macOS
//
//  Created by Reza Ali on 6/1/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

// This example shows how to generate custom geometry using C

import Metal
import MetalKit

import Satin

open class IcosahedronGeometry: SatinGeometry {
    var size: Float = 2
    var resolution: Int = 1

    public init(size: Float = 2, resolution: Int = 1) {
        self.size = size
        self.resolution = resolution
        super.init()
    }

    override open func generateGeometryData() -> GeometryData {
        generateIcosahedronGeometryData(size, Int32(resolution))
    }
}

class CustomGeometryRenderer: BaseRenderer {
    var scene = Object(label: "Scene")

    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: [0.0, 0.0, 6.0], near: 0.001, far: 100.0)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: metalView)
    lazy var renderer = Renderer(context: context)

    var mesh: Mesh!

    override func setup() {
        setupMesh()
    }

    deinit {
        cameraController.disable()
    }

    func setupMesh() {
        mesh = Mesh(geometry: IcosahedronGeometry(size: 1.0, resolution: 4), material: NormalColorMaterial(true))
        mesh.label = "Icosahedron"
        mesh.triangleFillMode = .lines
        scene.add(mesh)
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
