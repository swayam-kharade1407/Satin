//
//  PostProcessor.swift
//  Satin
//
//  Created by Reza Ali on 4/16/20.
//

import Metal

open class PostProcessor {
    public var label = "Post" {
        didSet {
            renderer.label = label + " Renderer"
            mesh.label = label + " Mesh"
            scene.label = label + " Scene"
        }
    }

    public var context: Context
    public var scene: Object
    public var mesh: Mesh
    public var camera = OrthographicCamera(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1)

    public var renderer: Renderer

    public init(context: Context, material: Material?) {
        self.context = context
        renderer = Renderer(context: context)
        renderer.label = label + " Processor"

        mesh = Mesh(geometry: QuadGeometry(), material: material)
        scene = Object(label: "Scene", [mesh])
        scene.apply { [weak self] object in
            guard let self else { return }
            object.context = self.context
        }
    }

    open func update() {
        camera.update()
        scene.update()
    }

    open func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, renderTarget: MTLTexture) {
        update()
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera,
            renderTarget: renderTarget
        )
    }

    open func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        update()
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    open func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, viewports: [MTLViewport], viewMappings: [MTLVertexAmplificationViewMapping] = [], renderTarget: MTLTexture) {
        update()
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            cameras: [camera, camera],
            viewports: viewports,
            viewMappings: viewMappings,
            renderTarget: renderTarget
        )
    }

    open func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, viewports: [MTLViewport], viewMappings: [MTLVertexAmplificationViewMapping] = []) {
        update()
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            cameras: [camera, camera],
            viewports: viewports,
            viewMappings: viewMappings
        )
    }

    open func resize(size: (width: Float, height: Float), scaleFactor: Float) {
        renderer.resize(size)
    }
}
