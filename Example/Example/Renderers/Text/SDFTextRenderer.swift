//
//  TextRenderer.swift
//  Example
//
//  Created by Reza Ali on 6/27/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Satin
import SatinCore

class SDFTextRenderer: BaseRenderer {
    lazy var fontTexture: MTLTexture? = {
        let loader = MTKTextureLoader(device: device)
        do {
            let options: [MTKTextureLoader.Option: Any] = [
                MTKTextureLoader.Option.SRGB: false,
                MTKTextureLoader.Option.generateMipmaps: false
            ]
            return try loader.newTexture(URL: sharedAssetsURL.appendingPathComponent("Fonts/SFProRounded/SFProRoundedBold64.png"), options: options)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }()

    lazy var mesh = {
        let mesh = Mesh(geometry: QuadGeometry(size: 1.0), material: BasicColorMaterial(color: [1, 0, 0, 0.5], blending: .alpha))
        mesh.scale.x = 8.0
        mesh.material?.depthWriteEnabled = false
        return mesh
    }()

    lazy var scene = Object(label: "Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat)
    lazy var camera = PerspectiveCamera(position: [0, 0, 5], near: 0.1, far: 100.0, fov: 60)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: metalView)
    lazy var renderer = Renderer(context: context)

    lazy var textMesh: TextMesh = {
        let fontAtlas = try! FontAtlas.load(url: sharedAssetsURL.appendingPathComponent("Fonts/SFProRounded/SFProRoundedBold64.json"))
        return TextMesh(geometry: TextGeometry(text: "Hello World", font: fontAtlas), material: TextMaterial(color: .one, fontTexture: fontTexture))
    }()

    override func setup() {
        textMesh.scale = .init(repeating: 1.0/64.0)
        textMesh.position.y = 9.5/64.0
        scene.add(textMesh)
        renderer.compile(scene: scene, camera: camera)
    }

    deinit {
        cameraController.disable()
    }

    var frame: Float = 0
    override func update() {
        textMesh.text = "\(frame)"
        frame -= 1
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
