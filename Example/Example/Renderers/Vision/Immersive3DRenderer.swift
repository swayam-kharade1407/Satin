//
//  ImmersiveRenderer3D.swift
//  Example
//
//  Created by Reza Ali on 1/23/24.
//  Copyright © 2024 Hi-Rez. All rights reserved.
//

#if os(visionOS)

import CompositorServices
import Metal
import Satin

class Immersive3DRenderer: MetalLayerRenderer {
    let mesh = Mesh(geometry: IcoSphereGeometry(radius: 0.5, resolution: 0), material: NormalColorMaterial(true))

    lazy var startTime = getTime()
    lazy var scene = Object(label: "Scene", [mesh])
    lazy var context = Context(
        device: device,
        sampleCount: sampleCount,
        colorPixelFormat: colorPixelFormat,
        depthPixelFormat: depthPixelFormat,
        vertexAmplificationCount: layerRenderer.configuration.layout == .layered ? 2 : 1
    )
    lazy var renderer = Renderer(context: context, clearColor: .zero)

    override var layerLayout: LayerRenderer.Layout { .layered }

    override func setup() {
        mesh.position.y = 1.0
        mesh.position.z = -1
    }

    override func update() {
        let theta = Float(getTime() - startTime)
        mesh.orientation = simd_quatf(angle: theta * 0.75, axis: simd_normalize(simd_make_float3(sin(theta), cos(theta), 1.0)))
        scene.update()
    }

    override func draw(
        frame: LayerRenderer.Frame,
        renderPassDescriptor: MTLRenderPassDescriptor,
        commandBuffer: MTLCommandBuffer,
        cameras: [PerspectiveCamera],
        viewports: [MTLViewport],
        viewMappings: [MTLVertexAmplificationViewMapping]
    ) {
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            cameras: cameras,
            viewports: viewports,
            viewMappings: viewMappings
        )
    }

//    override func drawView(view: Int, frame: LayerRenderer.Frame, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, camera: PerspectiveCamera, viewport: MTLViewport) {
//        renderer.draw(
//            renderPassDescriptor: renderPassDescriptor,
//            commandBuffer: commandBuffer,
//            scene: scene,
//            camera: camera,
//            viewport: viewport
//        )
//    }
}

#endif
