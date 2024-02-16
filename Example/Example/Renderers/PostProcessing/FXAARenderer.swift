//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 10/2/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Satin

class FXAARenderer: BaseRenderer {
    class FxaaMaterial: SourceMaterial {}

    // MARK: Render to Texture

    var renderTexture: MTLTexture!
    var updateRenderTexture = true

    lazy var fxaaMaterial = FxaaMaterial(pipelinesURL: pipelinesURL)

    lazy var fxaaProcessor: PostProcessor = {
        let pp = PostProcessor(context: Context(device: context.device, sampleCount: context.sampleCount, colorPixelFormat: context.colorPixelFormat), material: fxaaMaterial)
        pp.mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) in
            renderEncoder.setFragmentTexture(self.renderTexture, index: FragmentTextureIndex.Custom0.rawValue)
        }
        pp.label = "FXAA Post Processor"
        return pp
    }()

    lazy var mesh: Mesh = {
        let mesh = Mesh(
            geometry:
            ExtrudedTextGeometry(
                text: "FXAA",
                fontName: "Helvetica",
                fontSize: 1,
                distance: 0.5,
                pivot: [0, 0]
            ),
            material: BasicDiffuseMaterial(hardness: 1.0)
        )
        return mesh
    }()

    var camera = PerspectiveCamera(position: [0, 0, 9], near: 0.001, far: 100.0)

    lazy var scene = Object(label: "Scene", [mesh])
    lazy var context = Context(device: device, sampleCount: sampleCount, colorPixelFormat: colorPixelFormat, depthPixelFormat: depthPixelFormat, stencilPixelFormat: stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: metalView)
    lazy var renderer = Renderer(context: context)

    deinit {
        cameraController.disable()
    }

    override func update() {
        if updateRenderTexture {
            renderTexture = createTexture("Render Texture", context.colorPixelFormat)
            updateRenderTexture = false
        }

        cameraController.update()
        camera.update()
        scene.update()
    }

    override func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera,
            renderTarget: renderTexture
        )
        fxaaProcessor.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }

    override func resize(size: (width: Float, height: Float), scaleFactor: Float) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
        fxaaProcessor.resize(size: size, scaleFactor: scaleFactor)
        updateRenderTexture = true
        fxaaMaterial.set("Inverse Resolution", 1.0 / simd_make_float2(size.width, size.height))
    }

    func createTexture(_ label: String, _ pixelFormat: MTLPixelFormat) -> MTLTexture? {
        if metalView.drawableSize.width > 0, metalView.drawableSize.height > 0 {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = pixelFormat
            descriptor.width = Int(metalView.drawableSize.width)
            descriptor.height = Int(metalView.drawableSize.height)
            descriptor.sampleCount = 1
            descriptor.textureType = .type2D
            descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            guard let texture = context.device.makeTexture(descriptor: descriptor) else { return nil }
            texture.label = label
            return texture
        }
        return nil
    }
}
