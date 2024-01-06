//
//  Renderer.swift
//  Obj-macOS
//
//  Created by Reza Ali on 5/23/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit
import ModelIO

import Forge
import Satin

class LoadObjRenderer: BaseRenderer {
    override var modelsURL: URL { sharedAssetsURL.appendingPathComponent("Models") }

    var scene = Object(label: "Scene")
    var camera = PerspectiveCamera(position: [0.0, 0.0, 9.0], near: 0.001, far: 100.0)

    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    override func setup() {
        loadOBJ(url: modelsURL.appendingPathComponent("Suzanne").appendingPathComponent("Suzanne.obj"))
    }

    deinit {
        cameraController.disable()
    }

    func loadOBJ(url: URL) {
        let asset = MDLAsset(url: url, vertexDescriptor: SatinModelIOVertexDescriptor(), bufferAllocator: MTKMeshBufferAllocator(device: context.device))
        let geometry = Geometry()
        let mesh = Mesh(geometry: geometry, material: BasicDiffuseMaterial(0.0))
        mesh.label = "Suzanne"

        let geo = mesh.geometry
        let object0 = asset.object(at: 0)
        if let objMesh = object0 as? MDLMesh {
            objMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.0)

            let vertexBuffer = objMesh.vertexBuffers[VertexBufferIndex.Vertices.rawValue]
            let interleavedBuffer = InterleavedBuffer(
                index: .Vertices,
                data: vertexBuffer.map().bytes,
                stride: vertexBuffer.length / objMesh.vertexCount,
                count: objMesh.vertexCount,
                source: vertexBuffer
            )

            var offset = 0
            geometry.addAttribute(Float4InterleavedBufferAttribute(parent: interleavedBuffer, offset: offset), for: .Position)
            offset += MemoryLayout<Float>.size * 4
            geometry.addAttribute(Float3InterleavedBufferAttribute(parent: interleavedBuffer, offset: offset), for: .Normal)
            offset += MemoryLayout<Float>.size * 4
            geometry.addAttribute(Float2InterleavedBufferAttribute(parent: interleavedBuffer, offset: offset), for: .Texcoord)

            guard let submeshes = objMesh.submeshes, let first = submeshes.firstObject, let sub: MDLSubmesh = first as? MDLSubmesh else { return }

            let indexBuffer = sub.indexBuffer(asIndexType: .uInt32)
            geometry.setElements(
                ElementBuffer(
                    type: .uint32,
                    data: indexBuffer.map().bytes,
                    count: sub.indexCount,
                    source: indexBuffer
                )
            )
        }

        mesh.scale = simd_float3(repeating: 2.0)
        scene.add(mesh)
    }

    override func update() {
        cameraController.update()
        camera.update()
        scene.update()
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }

    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        let pt = normalizePoint(mtkView.convert(event.locationInWindow, from: nil), mtkView.frame.size)
        let results = raycast(camera: camera, coordinate: pt, object: scene)
        for result in results {
            print(result.object.label)
            print(result.position)
        }
    }

    #elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        if let first = touches.first {
            let point = first.location(in: mtkView)
            let size = mtkView.frame.size
            let pt = normalizePoint(point, size)
            let results = raycast(camera: camera, coordinate: pt, object: scene)
            for result in results {
                print(result.object.label)
                print(result.position)
            }
        }
    }
    #endif

    func normalizePoint(_ point: CGPoint, _ size: CGSize) -> simd_float2 {
        #if os(macOS)
        return 2.0 * simd_make_float2(Float(point.x / size.width), Float(point.y / size.height)) - 1.0
        #else
        return 2.0 * simd_make_float2(Float(point.x / size.width), 1.0 - Float(point.y / size.height)) - 1.0
        #endif
    }
}
