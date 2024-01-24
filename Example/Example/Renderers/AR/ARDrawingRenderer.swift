//
//  ARDrawingRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/15/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Metal
import MetalKit

import SatinCore
import Satin

import SwiftUI

class ARDrawingRenderer: BaseRenderer {
    class RainbowMaterial: SourceMaterial {}

    // MARK: - AR

    var session = ARSession()

    // MARK: - 3D

    lazy var material = RainbowMaterial(pipelinesURL: pipelinesURL)
    lazy var mesh = InstancedMesh(geometry: IcoSphereGeometry(radius: 0.03, resolution: 3), material: material, count: 20000)
    lazy var scene = Object(label: "Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat)
    lazy var camera = ARPerspectiveCamera(session: session, metalView: metalView, near: 0.01, far: 100.0)
    lazy var renderer = {
        let renderer = Satin.Renderer(context: context)
        renderer.label = "Content Renderer"
        renderer.setClearColor(.zero)
        renderer.colorLoadAction = .load
        renderer.depthLoadAction = .load
        return renderer
    }()

    private lazy var startTime: CFAbsoluteTime = getTime()
    private lazy var time: CFAbsoluteTime = getTime()

    // MARK: - Interaction

    var touchDown = false
    var clearDrawing = false

    // MARK: - Background

    var backgroundRenderer: ARBackgroundDepthRenderer!

    // MARK: - Init

    override init() {
        super.init()

        let config = ARWorldTrackingConfiguration()
        config.frameSemantics = [.smoothedSceneDepth]
        session.run(config)
    }

    // MARK: - Deinit

    override func cleanup() {
        session.pause()
    }

    // MARK: - Setup

    override func setup() {
        metalView.preferredFramesPerSecond = 60

        mesh.drawCount = 0
        backgroundRenderer = ARBackgroundDepthRenderer(
            context: context,
            session: session,
            sessionPublisher: ARSessionPublisher(session: session),
            metalView: metalView,
            near: camera.near,
            far: camera.far
        )

        renderer.compile(scene: scene, camera: camera)
    }

    // MARK: - Update

    override func update() {
        updateDrawing()
        updateMaterial()
        camera.update()
        scene.update()
    }

    // MARK: - Draw

    override func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        backgroundRenderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer
        )

        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    // MARK: - Resize

    override func resize(size: (width: Float, height: Float), scaleFactor: Float) {
        renderer.resize(size)
        backgroundRenderer.resize(size: size, scaleFactor: scaleFactor)
    }

    // MARK: - Interactions

    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
        touchDown = true
    }

    override func touchesEnded(_: Set<UITouch>, with _: UIEvent?) {
        touchDown = false
    }

    // MARK: - Updates

    public func clear() {
        clearDrawing = true
    }

    private func updateDrawing() {
        if clearDrawing {
            mesh.drawCount = 0
            clearDrawing = false
        } else if touchDown, let currentFrame = session.currentFrame {
            add(simd_mul(currentFrame.camera.transform, translationMatrixf(0, 0, -0.2)))
        }
    }

    private func add(_ transform: simd_float4x4) {
        if let index = mesh.drawCount {
            mesh.drawCount = index + 1
            mesh.setMatrixAt(index: index, matrix: transform)
        }
    }

    private func updateMaterial() {
        time = getTime() - startTime
        material.set("Time", Float(time))
    }
}

#endif
