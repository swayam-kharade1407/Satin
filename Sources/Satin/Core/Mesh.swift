//
//  Mesh.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import SatinCore
import simd

open class Mesh: Object, Renderable {
    public var opaque: Bool { material!.blending == .disabled }
    public var doubleSided: Bool = false

    public var renderOrder = 0
    public var renderPass = 0

    public var lighting: Bool { material?.lighting ?? false }

    public var receiveShadow = false {
        didSet {
            if receiveShadow != oldValue {
                material?.receiveShadow = receiveShadow
                for submesh in submeshes {
                    submesh.material?.receiveShadow = receiveShadow
                }
            }
        }
    }

    public var castShadow = false {
        didSet {
            if castShadow != oldValue {
                material?.castShadow = castShadow
                for submesh in submeshes {
                    submesh.material?.castShadow = castShadow
                }
            }
        }
    }

    public var cullMode: MTLCullMode = .back
    public var triangleFillMode: MTLTriangleFillMode = .fill
    public var windingOrder: MTLWinding {
        get {
            geometry.windingOrder
        }
        set {
            geometry.windingOrder = newValue
        }
    }

    open var drawable: Bool {
        guard instanceCount > 0, !geometry.vertexBuffers.isEmpty, uniforms != nil else { return false }

        if submeshes.isEmpty, let material = material, material.pipeline != nil {
            return true
        } else if let submesh = submeshes.first, let material = submesh.material, material.pipeline != nil {
            return true
        } else {
            return false
        }
    }

    public var instanceCount = 1

    var uniforms: VertexUniformBuffer?

    public var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> Void)?

    open var geometry = Geometry() {
        didSet {
            if geometry != oldValue {
                setupGeometry()
                _updateLocalBounds = true
            }
        }
    }

    open var material: Material? {
        didSet {
            if material != oldValue {
                material?.vertexDescriptor = geometry.vertexDescriptor
                setupMaterial()
            }
        }
    }

    open var materials: [Material] {
        var allMaterials = [Material]()
        if let material = material {
            allMaterials.append(material)
        }
        for submesh in submeshes {
            if let material = submesh.material {
                allMaterials.append(material)
            }
        }
        return allMaterials
    }

    internal var geometrySubscription: AnyCancellable?

    public internal(set) var submeshes: [Submesh] = []

    public init(label: String = "Mesh", geometry: Geometry, material: Material?) {
        self.geometry = geometry
        self.material = material
        super.init(label)
    }

    // MARK: - Decode

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    // MARK: - Deinit

    deinit {
        cleanupGeometrySubscriber()
    }

    // MARK: - Setup

    override open func setup() {
        setupGeometry()
        setupSubmeshes()
        setupMaterial()
        setupUniforms()
    }

    internal func cleanupGeometrySubscriber() {
        geometrySubscription?.cancel()
        geometrySubscription = nil
    }

    open func setupGeometry() {
        guard let context = context else { return }
        geometrySubscription = geometry.onUpdate.sink { [weak self] geo in
            guard let self = self else { return }
            self.updateBounds = true
            self.material?.vertexDescriptor = geo.vertexDescriptor
        }
        geometry.context = context
    }

    open func setupSubmeshes() {
        guard let context = context else { return }
        for submesh in submeshes { submesh.context = context }
    }

    open func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.vertexDescriptor = geometry.vertexDescriptor
        material.context = context
    }

    open func setupUniforms() {
        guard let context = context, uniforms == nil else { return }
        uniforms = VertexUniformBuffer(device: context.device)
    }

    // MARK: - Binding

    open func bind(renderEncoderState: RenderEncoderState, shadow: Bool) {
        bindUniforms(renderEncoderState: renderEncoderState)
        bindGeometry(renderEncoderState: renderEncoderState, shadow: shadow)
    }

    open func bindUniforms(renderEncoderState: RenderEncoderState) {
        renderEncoderState.vertexUniforms = uniforms
    }

    open func bindGeometry(renderEncoderState: RenderEncoderState, shadow: Bool) {
        geometry.bind(renderEncoderState: renderEncoderState, shadow: shadow)
    }

    // MARK: - Update

    override open func update() {
        geometry.update()
        material?.update()
        for submesh in submeshes { submesh.update() }
        super.update()
    }

    override open func encode(_ commandBuffer: MTLCommandBuffer) {
        geometry.encode(commandBuffer)
        material?.encode(commandBuffer)
        for submesh in submeshes { submesh.encode(commandBuffer) }
        super.encode(commandBuffer)
    }

    override open func update(camera: Camera, viewport: simd_float4) {
        geometry.update(camera: camera, viewport: viewport)
        material?.update(camera: camera, viewport: viewport)
        for submesh in submeshes { submesh.update(camera: camera, viewport: viewport) }
        uniforms?.update(object: self, camera: camera, viewport: viewport)
        super.update(camera: camera, viewport: viewport)
    }

    // MARK: - Draw

    open func draw(renderEncoderState: RenderEncoderState, shadow: Bool) {
        draw(renderEncoderState: renderEncoderState, instanceCount: instanceCount, shadow: shadow)
    }

    open func draw(renderEncoderState: RenderEncoderState, instanceCount: Int, shadow: Bool) {
        bind(renderEncoderState: renderEncoderState, shadow: shadow)

        if !submeshes.isEmpty {
            for submesh in submeshes where submesh.visible {
                submesh.bind(renderEncoderState: renderEncoderState, shadow: shadow)
                submesh.draw(renderEncoderState: renderEncoderState, instanceCount: instanceCount)
            }
        } else {
            material?.bind(renderEncoderState: renderEncoderState, shadow: shadow)
            geometry.draw(renderEncoderState: renderEncoderState, instanceCount: instanceCount)
        }
    }

    open func addSubmesh(_ submesh: Submesh) {
        submesh.parent = self
        submeshes.append(submesh)
    }

    // MARK: - Comoute Bounds

    override open func computeBounds() -> Bounds {
        geometry.bounds
    }

    override open func computeLocalBounds() -> Bounds {
        return transformBounds(bounds, localMatrix)
    }

    override open func computeWorldBounds() -> Bounds {
        var result = transformBounds(bounds, worldMatrix)
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

            /*
             let v0 = getVertex(index: triangle.i0)
             let v1 = getVertex(index: triangle.i1)
             let v2 = getVertex(index: triangle.i2)

             uv: v0.uv * bc.x + v1.uv * bc.y + v2.uv * bc.z,
             */

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
