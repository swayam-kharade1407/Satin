//
//  ImmersiveRenderer3D.swift
//  Example
//
//  Created by Reza Ali on 1/23/24.
//  Copyright © 2024 Hi-Rez. All rights reserved.
//

#if os(visionOS)

import Satin
import Metal
import CompositorServices

class Immersive3DRenderer: MetalLayerRenderer {
    let mesh = Mesh(geometry: IcoSphereGeometry(radius: 0.25, resolution: 0), material: BasicDiffuseMaterial(0.7))

    lazy var startTime = getTime()
    lazy var scene = Object(label: "Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat)
    lazy var renderer = Renderer(context: context)

    override func setup() {
        mesh.position.z = -1
    }

    override func update() {
        let theta = Float(getTime() - startTime)
        mesh.orientation = simd_quatf(angle: theta * 0.25, axis: simd_normalize(simd_make_float3(sin(theta), cos(theta), 1.0)))
        scene.update()
    }

    override func drawView(frame: LayerRenderer.Frame, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, camera: PerspectiveCamera, viewport: MTLViewport) {
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera,
            viewport: viewport
        )
    }
}

#endif
