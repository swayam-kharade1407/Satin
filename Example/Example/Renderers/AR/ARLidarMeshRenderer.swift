//
//  ARLidarMeshRenderer.swift
//  Example
//
//  Created by Reza Ali on 4/10/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Combine
import Metal

import Satin

class ARLidarMeshRenderer: BaseRenderer {
    var session: ARSession { sessionPublisher.session }
    private let sessionPublisher = ARSessionPublisher(session: ARSession())
    private var anchorsUpdatedSubscription: AnyCancellable?
    private var anchorsAddedSubscription: AnyCancellable?

    class LidarMeshMaterial: SourceMaterial {}

    lazy var material: LidarMeshMaterial = {
        let material = LidarMeshMaterial(pipelinesURL: pipelinesURL)
        material.blending = .alpha
        material.set("Color", [1.0, 1.0, 1.0, 0.25])
        material.vertexDescriptor = ARLidarMeshVertexDescriptor()
        return material
    }()

    var lidarMeshes: [UUID: ARLidarMesh] = [:]

    var scene = Object(label: "Scene")

    lazy var context = Context(device, sampleCount, colorPixelFormat, .depth32Float)
    lazy var camera = ARPerspectiveCamera(session: session, metalView: metalView, near: 0.01, far: 100.0)
    lazy var renderer = Satin.Renderer(context: context)

    var backgroundRenderer: ARBackgroundRenderer!

    override var depthPixelFormat: MTLPixelFormat {
        .invalid
    }

    override func setup() {
        metalView.preferredFramesPerSecond = 60

        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        session.run(config)

        renderer.colorLoadAction = .load

        backgroundRenderer = ARBackgroundRenderer(
            context: Context(device, 1, colorPixelFormat),
            session: session
        )

        anchorsUpdatedSubscription = sessionPublisher.updatedAnchorsPublisher.sink { [weak self] anchors in
            guard let self else { return }
            for anchor in anchors {
                if let meshAnchor = anchor as? ARMeshAnchor {
                    let id = anchor.identifier
                    if let lidarMesh = self.lidarMeshes[id] {
                        lidarMesh.meshAnchor = meshAnchor
                    }
                }
            }
        }

        anchorsAddedSubscription = sessionPublisher.updatedAnchorsPublisher.sink { [weak self] anchors in
            guard let self else { return }
            for anchor in anchors {
                if let meshAnchor = anchor as? ARMeshAnchor {
                    let id = anchor.identifier
                    let mesh = ARLidarMesh(meshAnchor: meshAnchor, material: material)
                    mesh.triangleFillMode = .lines
                    self.lidarMeshes[id] = mesh
                    self.scene.add(mesh)
                }
            }
        }
    }

    override func update() {
        camera.update()
        scene.update()
    }

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

    override func resize(size: (width: Float, height: Float), scaleFactor: Float) {
        renderer.resize(size)
        backgroundRenderer.resize(size: size, scaleFactor: scaleFactor)
    }

    override func cleanup() {
        session.pause()
    }
}

#endif
