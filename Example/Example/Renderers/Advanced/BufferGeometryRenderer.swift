//
//  BufferGeometryRenderer.swift
//  Example
//
//  Created by Reza Ali on 7/13/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Satin

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

    func isDrawable(renderContext: Context) -> Bool {
        guard material != nil,
              !geometry.vertexBuffers.isEmpty,
              instanceCount > 0,
              vertexUniforms[renderContext] != nil else { return false }
        return true
    }

    var preDraw: ((MTLRenderCommandEncoder) -> Void)?

    var material: Material?
    var materials: [Material] = []

    var vertexUniforms: [Context: VertexUniformBuffer] = [:]

    public init(label: String = "Buffer Geometry Mesh", geometry: Geometry, material: Material) {
        self.geometry = geometry
        self.material = material
        super.init(label: label)
    }

    required init(from decoder: Decoder) throws {
        fatalError("Not Implemented")
    }

    override func setup() {
        setupVertexUniforms()
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

    func setupVertexUniforms() {
        guard let context = context, vertexUniforms[context] == nil else { return }
        vertexUniforms[context] = VertexUniformBuffer(context: context)
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

    override func update(
        renderContext: Context,
        camera: Camera,
        viewport: simd_float4,
        index: Int
    ) {
        vertexUniforms[renderContext]?.update(
            object: self,
            camera: camera,
            viewport: viewport,
            index: index
        )

        super.update(
            renderContext: renderContext,
            camera: camera,
            viewport: viewport,
            index: index
        )
    }

    func draw(renderContext: Context, renderEncoderState: RenderEncoderState, shadow: Bool) {
        if let material, let shader = material.shader {
            if shader.vertexWantsVertexUniforms {
                renderEncoderState.vertexVertexUniforms = vertexUniforms[renderContext]
            }

            if shader.vertexWantsMaterialUniforms {
                renderEncoderState.fragmentVertexUniforms = vertexUniforms[renderContext]
            }

            material.bind(
                renderContext: renderContext,
                renderEncoderState: renderEncoderState,
                shadow: shadow
            )
        }
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
            ray: worldMatrixInverse.act(ray),
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
    }
}

class BufferGeometryRenderer: BaseRenderer {
    var geometryData = createGeometryData()
    var geometry = Geometry()
    lazy var mesh = BufferGeometryMesh(geometry: geometry, material: NormalColorMaterial())

    var intersectionMesh: Mesh = {
        let mesh = Mesh(geometry: IcoSphereGeometry(radius: 0.1, resolution: 2), material: BasicColorMaterial(color: [0.0, 1.0, 0.0, 1.0], blending: .disabled))
        mesh.label = "Intersection Mesh"
        mesh.renderPass = 1
        mesh.visible = false
        return mesh
    }()

    lazy var scene = Object(label: "Scene", [mesh, intersectionMesh])

    lazy var camera = PerspectiveCamera(position: [0, 0, -5], near: 0.01, far: 100.0, fov: 30)
    lazy var renderer = Renderer(context: defaultContext)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: metalView)

    let interleaved = true

    override func setup() {
        if interleaved {
            setupInterleavedBufferGeometry(size: 1.0)
        } else {
            setupBufferGeometry()
        }

        camera.lookAt(target: .zero)

#if os(visionOS)
        renderer.setClearColor(.zero)
        metalView.backgroundColor = .clear
#endif
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

    // MARK: Geometry Generation

    func setupInterleavedBufferGeometry(size: Float) {
        freeGeometryData(&geometryData)
//        var geoData = SatinCore.generateQuadGeometryData(1.0)
//        var geoData = SatinCore.generateBoxGeometryData(1, 1, 1, 0, 0, 0, 1, 1, 1)
        geometryData = generateRoundedBoxGeometryData(size, size, size, 0.25, 3)

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
            geometry.addAttribute(Float3InterleavedBufferAttribute(parent: interleavedBuffer, offset: offset), for: .Position)
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
        intersect(coordinate: normalizePoint(metalView.convert(event.locationInWindow, from: nil), metalView.frame.size))
    }

#elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        if let first = touches.first {
            intersect(coordinate: normalizePoint(first.location(in: metalView), metalView.frame.size))
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
