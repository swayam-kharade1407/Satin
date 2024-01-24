//
//  Renderer.swift
//  2D-macOS
//
//  Created by Reza Ali on 4/22/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Satin

class Renderer2D: BaseRenderer {
    let mesh = Mesh(label: "Quad", geometry: PlaneGeometry(size: 700), material: UvColorMaterial())

    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat)

    var camera = OrthographicCamera()
    lazy var cameraController = OrthographicCameraController(camera: camera, view: metalView)
    lazy var scene = Object(label: "Scene", [mesh])
    lazy var renderer = Satin.Renderer(context: context)

    override var depthPixelFormat: MTLPixelFormat {
        .invalid
    }

    override func update() {
        cameraController.update()
        camera.update()
        scene.update()
    }

    override func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        print("draw - Renderer2D")
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    override func resize(size: (width: Float, height: Float), scaleFactor: Float) {
        cameraController.resize(size)
        renderer.resize(size)
    }

    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        let pt = normalizePoint(metalView.convert(event.locationInWindow, from: nil), metalView.frame.size)
        intersect(coordinate: pt)
    }

    #elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        if let first = touches.first {
            let point = first.location(in: metalView)
            let size = metalView.frame.size
            let pt = normalizePoint(point, size)
            intersect(coordinate: pt)
        }
    }
    #endif

    func intersect(coordinate: simd_float2) {
        let results = raycast(camera: camera, coordinate: coordinate, object: scene)
        if let result = results.first {
            print(result.object.label)
            print(result.position)
        }
    }

    func normalizePoint(_ point: CGPoint, _ size: CGSize) -> simd_float2 {
        #if os(macOS)
        return 2.0 * simd_make_float2(Float(point.x / size.width), Float(point.y / size.height)) - 1.0
        #else
        return 2.0 * simd_make_float2(Float(point.x / size.width), 1.0 - Float(point.y / size.height)) - 1.0
        #endif
    }
}
