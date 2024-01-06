//
//  ARPlanesRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/22/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)
import ARKit
import Metal
import MetalKit

import Forge
import Satin
import SatinCore
import SwiftUI

class ARPlaneGeometry: Geometry {

    let positionBuffer = Float3BufferAttribute(defaultValue: .zero, data: [])
    let texcoodsBuffer = Float2BufferAttribute(defaultValue: .zero, data: [])
    let indicesBuffer = ElementBuffer(type: .uint16, data: nil, count: 0, source: [])

    var positions = [simd_float3]() {
        didSet {
            positionBuffer.data = positions
        }
    }

    var texcoords = [simd_float2]() {
        didSet {
            texcoodsBuffer.data = texcoords
        }
    }

    var indices = [Int16]() {
        didSet {
            indicesBuffer.updateData(data: &indices, count: indices.count, source: indices)
        }
    }

    public init() {
        super.init()
        addAttribute(positionBuffer, for: .Position)
        addAttribute(texcoodsBuffer, for: .Texcoord)
        setElements(indicesBuffer)
    }
}

class ARPlaneContainer: Object {
    var anchor: ARPlaneAnchor {
        didSet {
            updateAnchor()
        }
    }

    var geometry = ARPlaneGeometry()
    var planeMesh: Mesh
    var meshWireframe: Mesh

    init(label: String, anchor: ARPlaneAnchor, material: Satin.Material) {
        self.anchor = anchor

        let mat = material.clone()
        mat.set("Color", [Float.random(in: 0 ... 1), Float.random(in: 0 ... 1), Float.random(in: 0 ... 1), 0.25])

        planeMesh = Mesh(geometry: geometry, material: mat)
        meshWireframe = Mesh(geometry: geometry, material: mat)
        meshWireframe.triangleFillMode = .lines
        planeMesh.add(meshWireframe)

        super.init(label: label, [planeMesh])
        updateAnchor()
    }

    required init(from _: Decoder) throws { fatalError("Not implemented") }

    func updateAnchor() {
        updateTransform()
        updateGeometry()
    }

    func updateTransform() {
        worldMatrix = anchor.transform
    }

    func updateGeometry() {
        geometry.positions = anchor.geometry.vertices
        geometry.texcoords = anchor.geometry.textureCoordinates
        geometry.indices = anchor.geometry.triangleIndices
    }
}

class ARPlanesRenderer: BaseRenderer, ARSessionDelegate {
    // MARK: - AR

    var session = ARSession()

    lazy var planeMaterial: Satin.Material = {
        let material = BasicColorMaterial(.one, .additive)
        material.depthWriteEnabled = false
        return material
    }()

    fileprivate var planesMap: [ARAnchor: ARPlaneContainer] = [:]

    // MARK: - 3D

    lazy var scene = Object(label: "Scene")
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat)
    lazy var camera = ARPerspectiveCamera(session: session, mtkView: mtkView, near: 0.01, far: 100.0)
    lazy var renderer = {
        let renderer = Satin.Renderer(label: "Content Renderer", context: context)
        renderer.colorLoadAction = .load
        return renderer
    }()

    // MARK: - Background

    var backgroundRenderer: ARBackgroundRenderer!

    // MARK: - Setup MTKView

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.backgroundColor = .black
        metalKitView.preferredFramesPerSecond = 120
    }

    // MARK: - Init

    override init() {
        super.init()

        session.delegate = self
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        session.run(configuration)
    }

    // MARK: - Deinit

    override func cleanup() {
        session.pause()
    }

    // MARK: - Setup

    override func setup() {
        backgroundRenderer = ARBackgroundRenderer(context: Context(device, 1, colorPixelFormat), session: session)
        renderer.compile(scene: scene, camera: camera)
    }

    override func update() {
        camera.update()
        scene.update()
    }

    // MARK: - Draw

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

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

    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        backgroundRenderer.resize(size)
    }

    // MARK: - ARSession Delegate

    func session(_: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let plane = planesMap[anchor], let planeAnchor = anchor as? ARPlaneAnchor {
                plane.anchor = planeAnchor
            }
        }
    }

    func session(_: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if planesMap[anchor] == nil, let planeAnchor = anchor as? ARPlaneAnchor {
                let planeContainer = ARPlaneContainer(label: "\(planeAnchor.identifier)", anchor: planeAnchor, material: planeMaterial)
                planesMap[anchor] = planeContainer
                scene.add(planeContainer)
            }
        }
    }
}
#endif
