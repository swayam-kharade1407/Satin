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
    public var camera = OrthographicCamera()

    public var renderer: Renderer

    public init(label: String = "Post Processor", context: Context, material: Material?) {
        self.label = label
        self.context = context
        renderer = Renderer(context: context)
        renderer.label = label + " Processor"

        mesh = Mesh(geometry: QuadGeometry(), material: material)
        scene = Object(label: "Scene", [mesh])
    }

    open func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, renderTarget: MTLTexture) {
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera,
            renderTarget: renderTarget
        )
    }

    open func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    open func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, viewports: [MTLViewport], viewMappings: [MTLVertexAmplificationViewMapping] = [], renderTarget: MTLTexture) {
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
