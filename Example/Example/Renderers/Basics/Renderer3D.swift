//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 6/27/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

#if os(visionOS)
import CompositorServices
#endif

import Satin
import SatinCore

class Renderer3D: BaseRenderer {
    override public var label: String {
        "Renderer3D"
    }

    let mesh = Mesh(geometry: IcoSphereGeometry(radius: 1.0, resolution: 0), material: BasicDiffuseMaterial(0.7))

    var intersectionMesh: Mesh = {
        let mesh = Mesh(geometry: IcoSphereGeometry(radius: 0.05, resolution: 2), material: BasicColorMaterial(color: [0.0, 1.0, 0.0, 1.0], blending: .disabled))
        mesh.label = "Intersection Mesh"
        mesh.renderPass = 1
        mesh.visible = false
        return mesh
    }()

    lazy var startTime = getTime()
    lazy var scene = Object(label: "Scene", [mesh, intersectionMesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat)
    lazy var renderer = Satin.Renderer(context: context)

    lazy var camera = PerspectiveCamera(position: [0, 0, 5], near: 0.01, far: 100.0, fov: 30)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: metalView)

    override func setup() {
        camera.lookAt(target: .zero)
    }

    deinit {
        cameraController.disable()
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
