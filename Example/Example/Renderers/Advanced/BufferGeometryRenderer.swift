//
//  BufferGeometryRenderer.swift
//  Example
//
//  Created by Reza Ali on 7/13/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin
import SatinCore

class BufferGeometryMesh: Object, Renderable {
    var geometry: Geometry {
        didSet {
            if geometry != oldValue {
                setupGeometry()
                updateLocalBounds = true
            }
        }
    }

    var doubleSided: Bool = false
    var opaque: Bool { material?.blending == .disabled }

    var cullMode: MTLCullMode = .back
    var windingOrder: MTLWinding { geometry.windingOrder }
    var triangleFillMode: MTLTriangleFillMode = .fill

    var renderOrder: Int = 0
    var renderPass: Int = 0

    var lighting: Bool { material?.lighting ?? false }
    var receiveShadow: Bool { material?.receiveShadow ?? false }
    var castShadow: Bool { material?.castShadow ?? false }

    var instanceCount: Int = 1

    var drawable: Bool { material != nil && !geometry.vertexBuffers.isEmpty && instanceCount > 0 }

    var preDraw: ((MTLRenderCommandEncoder) -> Void)?

    var material: Material?
    var materials: [Material] = []

    var uniforms: VertexUniformBuffer?

    public init(label: String = "Buffer Geometry Mesh", geometry: Geometry, material: Material) {
        self.geometry = geometry
        self.material = material
        super.init(label)
    }

    required init(from decoder: Decoder) throws {
        fatalError("Not Implemented")
    }

    override func setup() {
        setupUniforms()
        setupGeometry()
        setupMaterial()
        super.setup()
    }

    func setupGeometry() {
        guard let context = context else { return }
        geometry.context = context
    }

    func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.vertexDescriptor = geometry.vertexDescriptor
        material.context = context
    }

    func setupUniforms() {
        guard let context = context else { return }
        uniforms = VertexUniformBuffer(device: context.device)
    }

    override func update() {
        geometry.update()
        material?.update()
        super.update()
    }

    override func encode(_ commandBuffer: MTLCommandBuffer) {
        geometry.encode(commandBuffer)
        material?.encode(commandBuffer)
        super.encode(commandBuffer)
    }

    override func update(camera: Camera, viewport: simd_float4) {
        geometry.update(camera: camera, viewport: viewport)
        material?.update(camera: camera, viewport: viewport)
        uniforms?.update(object: self, camera: camera, viewport: viewport)
        super.update(camera: camera, viewport: viewport)
    }

    func draw(renderEncoderState: RenderEncoderState, shadow: Bool) {
        renderEncoderState.vertexUniforms = uniforms
        material?.bind(renderEncoderState: renderEncoderState, shadow: shadow)
        geometry.bind(renderEncoderState: renderEncoderState, shadow: shadow)
        geometry.draw(renderEncoderState: renderEncoderState, instanceCount: instanceCount)
    }

    // MARK: - Comoute Bounds

    override open func computeLocalBounds() -> Bounds {
        return transformBounds(geometry.bounds, localMatrix)
    }

    override open func computeWorldBounds() -> Bounds {
        var result = transformBounds(geometry.bounds, worldMatrix)
        for child in children {
            result = mergeBounds(result, child.worldBounds)
        }
        return result
    }

    // MARK: - Intersect

    override open func intersect(ray: Ray, intersections: inout [RaycastResult], recursive: Bool = true, invisible: Bool = false) {
        guard visible || invisible, intersects(ray: ray) else { return }

        var geometryIntersections = [IntersectionResult]()
        geometry.intersect(
            ray: worldMatrix.inverse.act(ray),
            intersections: &geometryIntersections
        )

        var results = [RaycastResult]()
        for geometryIntersection in geometryIntersections {
            let hitPosition = simd_make_float3(
                worldMatrix * simd_make_float4(geometryIntersection.position, 1.0)
            )

            results.append(
                RaycastResult(
                    barycentricCoordinates: geometryIntersection.barycentricCoordinates,
                    distance: simd_length(hitPosition - ray.origin),
                    normal: normalMatrix * geometryIntersection.normal,
                    position: hitPosition,
                    primitiveIndex: geometryIntersection.primitiveIndex,
                    object: self,
                    submesh: nil
                )
            )
        }

        intersections.append(contentsOf: results)

        if recursive {
            for child in children {
                child.intersect(
                    ray: ray,
                    intersections: &intersections,
                    recursive: recursive,
                    invisible: invisible
                )
            }
        }

        intersections.sort { $0.distance < $1.distance }
    }
}

class BufferGeometryRenderer: BaseRenderer {
    var geometryData = createGeometryData()
    var geometry = Geometry()
    lazy var mesh = BufferGeometryMesh(geometry: geometry, material: NormalColorMaterial())

    var intersectionMesh: Mesh = {
        let mesh = Mesh(geometry: IcoSphereGeometry(radius: 0.1, resolution: 2), material: BasicColorMaterial([0.0, 1.0, 0.0, 1.0], .disabled))
        mesh.label = "Intersection Mesh"
        mesh.renderPass = 1
        mesh.visible = false
        return mesh
    }()

    lazy var scene = Object("Scene", [mesh, intersectionMesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: [0, 0, -5], near: 0.01, far: 100.0, fov: 30)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 120
    }

    let interleaved = true

    override func setup() {
        if interleaved {
            setupInterleavedBufferGeometry(size: 1.0)
        } else {
            setupBufferGeometry()
        }

//        camera.lookAt(target: .zero)
        renderer.compile(scene: scene, camera: camera)
    }

    deinit {
        freeGeometryData(&geometryData)
        cameraController.disable()
    }

    var theta: Float = 0.0

    override func update() {
        setupInterleavedBufferGeometry(size: 1.0 + 0.25 * sin(theta))
        cameraController.update()
        theta += 0.1

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

    // MARK: Geometry Generation

    func setupInterleavedBufferGeometry(size: Float) {
        freeGeometryData(&geometryData)
//        var geoData = SatinCore.generateQuadGeometryData(1.0)
//        var geoData = SatinCore.generateBoxGeometryData(1, 1, 1, 0, 0, 0, 1, 1, 1)
        geometryData = SatinCore.generateRoundedBoxGeometryData(size, size, size, 0.25, 3)

        // position (4) & normal (3) & uv (2)
        //        var data: [Float] = [
        //            -1.0, -1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0,
        //             1.0, -1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0,
        //             1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0,
        //             -1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0
        //        ]

        if let data = geometryData.vertexData {
            let vertexCount = Int(geometryData.vertexCount)
            let interleavedBuffer = InterleavedBuffer(
                index: .Vertices,
                data: data,
                stride: MemoryLayout<SatinVertex>.size,
                count: vertexCount,
                source: geometryData
            )

            if geometryData.indexCount > 0 {
                geometry.setElements(
                    ElementBuffer(
                        type: .uint32,
                        data: geometryData.indexData,
                        count: Int(geometryData.indexCount * 3),
                        source: geometryData
                    )
                )
            } else {
                geometry.setElements(nil)
            }

            var offset = 0
            geometry.addAttribute(Float4InterleavedBufferAttribute(parent: interleavedBuffer, offset: offset), for: .Position)
            offset += MemoryLayout<Float>.size * 4
            geometry.addAttribute(Float3InterleavedBufferAttribute(parent: interleavedBuffer, offset: offset), for: .Normal)
            offset += MemoryLayout<Float>.size * 4
            geometry.addAttribute(Float2InterleavedBufferAttribute(parent: interleavedBuffer, offset: offset), for: .Texcoord)
        }
    }

    func setupBufferGeometry() {
        geometry.addAttribute(
            Float4BufferAttribute(
                defaultValue: .zero,
                data: [
                    [-1.0, -1.0, 0.0, 1.0],
                    [1.0, -1.0, 0.0, 1.0],
                    [1.0, 1.0, 0.0, 1.0],
                    [-1.0, 1.0, 0.0, 1.0]
                ]
            ),
            for: .Position
        )

//        geometry.setAttribute(
//            Float3BufferAttribute(
//                index: .Position,
//                data: [
//                    [-1.0, -1.0, 0.0],
//                    [1.0, -1.0, 0.0],
//                    [1.0, 1.0, 0.0],
//                    [-1.0, 1.0, 0.0]
//                ]
//            )
//        )

        geometry.addAttribute(
            Float3BufferAttribute(
                defaultValue: .zero,
                data: [
                    [0.0, 0.0, 1.0],
                    [0.0, 0.0, 1.0],
                    [0.0, 0.0, 1.0],
                    [0.0, 0.0, 1.0]
                ]
            ),
            for: .Normal
        )

        geometry.addAttribute(
            Float2BufferAttribute(
                defaultValue: .zero,
                data: [
                    [0.0, 0.0],
                    [1.0, 0.0],
                    [1.0, 1.0],
                    [0.0, 1.0]
                ]
            ),
            for: .Texcoord
        )

        geometry.addAttribute(
            Float4BufferAttribute(
                defaultValue: .zero,
                data: [
                    [0.0, 0.0, 0.0, 1.0],
                    [0.0, 1.0, 0.0, 1.0],
                    [0.0, 0.0, 1.0, 1.0],
                    [1.0, 0.0, 0.0, 1.0]
                ]
            ),
            for: .Color
        )

        var elements = [0, 1, 2, 2, 3, 0]
        geometry.setElements(ElementBuffer(type: .uint32, data: &elements, count: 6, source: elements))
    }

#if os(macOS)
    override func mouseDown(with event: NSEvent) {
        intersect(coordinate: normalizePoint(mtkView.convert(event.locationInWindow, from: nil), mtkView.frame.size))
    }

#elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        if let first = touches.first {
            intersect(coordinate: normalizePoint(first.location(in: mtkView), mtkView.frame.size))
        }
    }
#endif

    func intersect(coordinate: simd_float2) {
        let results = raycast(camera: camera, coordinate: coordinate, object: scene)
        if let result = results.first {
            //            print(result.object.label)
            //            print(result.position)
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
