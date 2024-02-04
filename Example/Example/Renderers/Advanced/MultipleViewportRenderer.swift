//
//  MultipleViewportRenderer.swift
//  Example
//
//  Created by Reza Ali on 2/4/24.
//  Copyright © 2024 Hi-Rez. All rights reserved.
//

import Foundation

import Metal
import MetalKit
import Satin
import SatinCore

class MultipleViewportRenderer: BaseRenderer {
    let mesh = Mesh(geometry: IcoSphereGeometry(radius: 0.5, resolution: 0), material: BasicDiffuseMaterial(0.7))

    var intersectionMesh: Mesh = {
        let mesh = Mesh(geometry: IcoSphereGeometry(radius: 0.05, resolution: 2), material: BasicColorMaterial(color: [0.0, 1.0, 0.0, 1.0], blending: .disabled))
        mesh.label = "Intersection Mesh"
        mesh.renderPass = 1
        mesh.visible = false
        return mesh
    }()

    lazy var startTime = getTime()
    lazy var scene = Object(label: "Scene", [mesh, intersectionMesh])
    lazy var context = Context(device: device, sampleCount: sampleCount, colorPixelFormat: colorPixelFormat, depthPixelFormat: depthPixelFormat)
    lazy var renderer = Renderer(context: context)

    lazy var camera = PerspectiveCamera(position: [0, 0, 5], near: 0.01, far: 100.0, fov: 30)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: metalView)

    var tween: Tween?

    override func setup() {
        camera.lookAt(target: .zero)

#if os(visionOS)
        renderer.setClearColor(.zero)
        metalView.backgroundColor = .clear
#endif

        tween = Tweener
            .tweenScale(duration: 2.0, object: mesh, from: .one, to: .init(repeating: 2.0))
            .easing(.inOutBack)
            .pingPong()
            .loop()
            .start()
    }

    deinit {
        cameraController.disable()
        tween?.remove()
    }

    override func update() {
        cameraController.update()
        camera.update()

        mesh.orientation = simd_quatf(angle: Float(getTime() - startTime), axis: simd_normalize(simd_float3.one))
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

#if os(macOS)
    override func mouseDown(with event: NSEvent) {
        intersect(camera: camera, coordinate: normalizePoint(metalView.convert(event.locationInWindow, from: nil), metalView.frame.size))
    }

#elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        if let first = touches.first {
            intersect(camera: camera, coordinate: normalizePoint(first.location(in: metalView), metalView.frame.size))
        }
    }
#endif

    func intersect(camera: Camera, coordinate: simd_float2) {
        let results = raycast(camera: camera, coordinate: coordinate, object: scene)
        if let result = results.first {
            intersectionMesh.position = result.position
            intersectionMesh.visible = true
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
