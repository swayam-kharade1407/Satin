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

import Forge
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
    var scene = Object("Scene")

    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: [0.0, 0.0, 6.0], near: 0.001, far: 100.0)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)

    var mesh: Mesh!

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }

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
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }
}
