//
//  OrbitCameraControllerRenderer.swift
//  Example
//
//  Created by Reza Ali on 6/28/24.
//  Copyright © 2024 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Satin

final class OrbitCameraControllerRenderer: BaseRenderer {
    var gridInterval: Float = 1.0

    lazy var grid: Object = {
        let object = Object()
        let material = BasicColorMaterial(color: simd_make_float4(1.0, 1.0, 1.0, 1.0))
        let intervals = 5
        let intervalsf = Float(intervals)
        let geometryX = CapsuleGeometry(radius: 0.005, height: intervalsf, axis: .x)
        let geometryZ = CapsuleGeometry(radius: 0.005, height: intervalsf, axis: .z)
        for i in 0 ... intervals {
            let fi = Float(i)
            let meshX = Mesh(geometry: geometryX, material: material)
            let offset = remap(fi, 0.0, Float(intervals), -intervalsf * 0.5, intervalsf * 0.5)
            meshX.position = [0.0, 0.0, offset]
            object.add(meshX)

            let meshZ = Mesh(geometry: geometryZ, material: material)
            meshZ.position = [offset, 0.0, 0.0]
            object.add(meshZ)
        }
        return object
    }()

    lazy var axisMesh: Object = {
        let object = Object()
        let intervals = 5
        let intervalsf = Float(intervals)
        let radius = Float(0.005)
        let height = intervalsf

        let x = Mesh(
            geometry: CapsuleGeometry(radius: radius, height: height, axis: .x),
            material: BasicColorMaterial(color: simd_make_float4(1.0, 0.0, 0.0, 1.0))
        )
        x.position.x += height * 0.5
        object.add(x)

        let y = Mesh(geometry: CapsuleGeometry(radius: radius, height: height, axis: .y), material: BasicColorMaterial(color: simd_make_float4(0.0, 1.0, 0.0, 1.0)))
        y.position.y += height * 0.5
        object.add(y)

        let z = Mesh(geometry: CapsuleGeometry(radius: radius, height: height, axis: .z), material: BasicColorMaterial(color: simd_make_float4(0.0, 0.0, 1.0, 1.0)))
        z.position.z += height * 0.5
        object.add(z)

        return object
    }()

    let targetMesh = Mesh(
        geometry: RoundedBoxGeometry(size: 1.0, radius: 0.25, resolution: 3),
        material: NormalColorMaterial(true)
    )

    let targetPlane = Mesh(
        geometry: PlaneGeometry(size: 4, orientation: .zx, centered: true),
        material: BasicColorMaterial(color: [0, 1, 0, 0.25], blending: .alpha)
    )

    lazy var scene = Object(label: "Scene", [grid, axisMesh, targetPlane])
    lazy var context = Context(device: device, sampleCount: sampleCount, colorPixelFormat: colorPixelFormat, depthPixelFormat: depthPixelFormat)

    lazy var camera: PerspectiveCamera = {
        let pos = simd_make_float3(5.0, 5.0, 5.0)
        let camera = PerspectiveCamera(position: pos, near: 0.001, far: 200.0)

        camera.orientation = simd_quatf(from: [0, 0, 1], to: simd_normalize(pos))

        let forward = simd_normalize(camera.forwardDirection)
        let worldUp = Satin.worldUpDirection
        let right = -simd_normalize(simd_cross(forward, worldUp))
        let angle = acos(simd_dot(simd_normalize(camera.rightDirection), right))

        camera.orientation = simd_quatf(angle: angle, axis: forward) * camera.orientation

        return camera
    }()

    lazy var cameraController = OrbitPerspectiveCameraController(camera: camera, view: metalView)
    lazy var renderer: Renderer = .init(context: context)

    override func setup() {
        cameraController.target.add(targetMesh)

        scene.attach(cameraController.target)

        targetPlane.material?.depthWriteEnabled = false
        targetPlane.cullMode = .none

#if os(visionOS)
        renderer.setClearColor(.zero)
        metalView.backgroundColor = .clear
#endif
    }

    deinit {
        cameraController.disable()
    }

    override func update() {
        cameraController.update()
        targetMesh.orientation = cameraController.camera.worldOrientation.inverse
        targetPlane.position = cameraController.target.position
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
