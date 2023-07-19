//
//  PBRSubmeshRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/10/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class PBRSubmeshRenderer: BaseRenderer {
    override var modelsURL: URL { sharedAssetsURL.appendingPathComponent("Models") }
    override var texturesURL: URL { sharedAssetsURL.appendingPathComponent("Textures") }

    var scene = Scene("Scene", [Mesh(geometry: SkyboxGeometry(size: 250), material: SkyboxMaterial())])

    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera: PerspectiveCamera = {
        let pos = simd_make_float3(125.0, 125.0, 125.0)
        camera = PerspectiveCamera(position: pos, near: 0.01, far: 1000.0, fov: 45)
        camera.orientation = simd_quatf(from: [0, 0, 1], to: simd_normalize(pos))

        let forward = simd_normalize(camera.forwardDirection)
        let worldUp = Satin.worldUpDirection
        let right = -simd_normalize(simd_cross(forward, worldUp))
        let angle = acos(simd_dot(simd_normalize(camera.rightDirection), right))

        camera.orientation = simd_quatf(angle: angle, axis: forward) * camera.orientation
        return camera
    }()

    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)
    lazy var textureLoader = MTKTextureLoader(device: device)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    override func setup() {
        start("Setup")

        start("Loading HDRI")
        loadHdri()
        end()

        start("Model Setup")
        if let model = loadAsset(url: modelsURL.appendingPathComponent("chair_swan.usdz"), textureLoader: textureLoader) {
            print("loaded model")
            scene.add(model)
            let sceneBounds = scene.worldBounds
            model.position.y -= sceneBounds.size.y * 0.25
        }

        end()

        start("Bounds Calculation")

        end()

        start("Light Setup")
        let light = DirectionalLight(color: .one, intensity: 2.0)
        light.position = .init(repeating: 5.0)
        light.lookAt(target: scene.worldBounds.center)
        end()

        scene.add(light)
    }

    deinit {
        cameraController.disable()
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

    // MARK: - PBR Env

    func loadHdri() {
        let filename = "brown_photostudio_02_2k.hdr"
        if let hdr = loadHDR(device: device, url: texturesURL.appendingPathComponent(filename)) {
            scene.setEnvironment(texture: hdr)
        }
    }
}
