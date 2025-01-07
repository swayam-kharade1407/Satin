//
//  InstancedMesh.swift
//  Satin
//
//  Created by Reza Ali on 10/19/22.
//

import Combine
import Foundation
import Metal
import simd

#if SWIFT_PACKAGE
import SatinCore
#endif

public class InstancedMesh: Mesh {
    override public func isDrawable(renderContext: Context, shadow: Bool) -> Bool {
        guard instanceMatrixBuffer != nil, instanceMatricesUniforms.count >= instanceCount else { return false }

        if let drawCount = drawCount {
            if drawCount > 0 {
                return super.isDrawable(renderContext: renderContext, shadow: shadow)
            }
            else {
                return false
            }
        }
        else {
            return super.isDrawable(renderContext: renderContext, shadow: shadow)
        }
    }

    public var drawCount: Int? {
        didSet {
            if let drawCount = drawCount, drawCount > instanceCount {
                instanceCount = drawCount
                print("maxed out instances, adding more: \(instanceCount)")
            }
        }
    }

    override public var instanceCount: Int {
        didSet {
            if instanceCount != oldValue {
                instanceMatrices.reserveCapacity(instanceCount)
                instanceMatricesUniforms.reserveCapacity(instanceCount)
                while instanceMatrices.count < instanceCount {
                    instanceMatrices.append(matrix_identity_float4x4)
                    instanceMatricesUniforms.append(InstanceMatrixUniforms(modelMatrix: matrix_identity_float4x4, normalMatrix: matrix_identity_float3x3))
                }
                _setupInstanceMatrixBuffer = true
            }
        }
    }

    var instanceMatrices: [simd_float4x4]
    var instanceMatricesUniforms: [InstanceMatrixUniforms]

    private var transformSubscriber: AnyCancellable?
    private var _updateInstanceMatricesUniforms = true
    private var _setupInstanceMatrixBuffer = true
    private var _updateInstanceMatrixBuffer = true
    private var instanceMatrixBuffer: InstanceMatrixUniformBuffer?

    override public var material: Material? {
        didSet {
            material?.instancing = true
        }
    }

    public init(label: String = "Instanced Mesh", geometry: Geometry, material: Material?, count: Int) {
        material?.instancing = true

        instanceMatricesUniforms = .init(repeating: InstanceMatrixUniforms(modelMatrix: matrix_identity_float4x4, normalMatrix: matrix_identity_float3x3), count: count)

        instanceMatrices = .init(repeating: matrix_identity_float4x4, count: count)

        super.init(label: label, geometry: geometry, material: material)

        instanceCount = count

        transformSubscriber = transformPublisher.sink { [weak self] _ in
            self?._updateInstanceMatricesUniforms = true
        }
    }

    public required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    public func setMatrixAt(index: Int, matrix: matrix_float4x4) {
        guard index < instanceCount else { return }
        instanceMatrices[index] = matrix
        instanceMatricesUniforms[index].modelMatrix = simd_mul(worldMatrix, matrix)
        let n = instanceMatricesUniforms[index].modelMatrix.inverse.transpose
        instanceMatricesUniforms[index].normalMatrix = simd_float3x3(
            simd_make_float3(n.columns.0),
            simd_make_float3(n.columns.1),
            simd_make_float3(n.columns.2)
        )

        _updateInstanceMatrixBuffer = true
    }

    // MARK: - Instancing

    public func getMatrixAt(index: Int) -> matrix_float4x4 {
        guard index < instanceCount else { fatalError("Unable to get matrix at \(index)") }
        return instanceMatrices[index]
    }

    public func getWorldMatrixAt(index: Int) -> matrix_float4x4 {
        guard index < instanceCount else { fatalError("Unable to get world matrix at \(index)") }
        return instanceMatricesUniforms[index].modelMatrix
    }

    override public func setup() {
        super.setup()
        setupInstanceBuffer()
    }

    override public func update() {
        if _updateInstanceMatricesUniforms { updateInstanceMatricesUniforms() }
        if _setupInstanceMatrixBuffer { setupInstanceBuffer() }
        if _updateInstanceMatrixBuffer { updateInstanceBuffer() }
        super.update()
    }

    override public func bind(renderContext: Context, renderEncoderState: RenderEncoderState, shadow: Bool) {
        super.bind(
            renderContext: renderContext,
            renderEncoderState: renderEncoderState,
            shadow: shadow
        )
        renderEncoderState.vertexInstanceUniforms = instanceMatrixBuffer
    }

    // MARK: - Private Instancing

    func setupInstanceBuffer() {
        guard let context, instanceCount > 0 else { return }
        instanceMatrixBuffer = InstanceMatrixUniformBuffer(device: context.device, count: instanceCount)
        _setupInstanceMatrixBuffer = false
        _updateInstanceMatrixBuffer = true
    }

    func updateInstanceBuffer() {
        instanceMatrixBuffer?.update(data: instanceMatricesUniforms)
        _updateInstanceMatrixBuffer = false
    }

    func updateInstanceMatricesUniforms() {
        for i in 0 ..< instanceCount {
            instanceMatricesUniforms[i].modelMatrix = simd_mul(worldMatrix, instanceMatrices[i])
            let n = instanceMatricesUniforms[i].modelMatrix.inverse.transpose
            instanceMatricesUniforms[i].normalMatrix = simd_float3x3(
                simd_make_float3(n.columns.0),
                simd_make_float3(n.columns.1),
                simd_make_float3(n.columns.2)
            )
        }

        _updateInstanceMatricesUniforms = false
        _updateInstanceMatrixBuffer = true
    }

    override public func draw(renderContext: Context, renderEncoderState: RenderEncoderState, instanceCount: Int, shadow: Bool) {
        if let drawCount = drawCount {
            super.draw(
                renderContext: renderContext,
                renderEncoderState: renderEncoderState,
                instanceCount: min(drawCount, instanceCount),
                shadow: shadow
            )
        }
        else {
            super.draw(
                renderContext: renderContext,
                renderEncoderState: renderEncoderState,
                instanceCount: instanceCount,
                shadow: shadow
            )
        }
    }

    // MARK: - Intersections

    override public func computeLocalBounds() -> Bounds {
        var result = createBounds()
        for i in 0 ..< instanceCount {
            result = mergeBounds(result, transformBounds(bounds, getMatrixAt(index: i)))
        }
        return result
    }

    override public func computeWorldBounds() -> Bounds {
        var result = createBounds()
        for i in 0 ..< instanceCount {
            result = transformBounds(bounds, getWorldMatrixAt(index: i))
        }

        for child in children {
            result = mergeBounds(result, child.worldBounds)
        }
        return result
    }

    override public func intersects(ray: Ray) -> Bool {
        for i in 0 ..< instanceCount {
            if rayBoundsIntersect(getWorldMatrixAt(index: i).inverse.act(ray), bounds) {
                return true
            }
        }
        return false
    }

    override open func intersect(
        ray: Ray,
        intersections: inout [RaycastResult],
        options: RaycastOptions
    ) -> Bool {
        guard visible || options.invisible, intersects(ray: ray) else { return false }

        var geometryIntersections = [IntersectionResult]()

        var instanceIntersections = [Int]()
        for i in 0 ..< instanceCount {
            let preCount = geometryIntersections.count
            geometry.intersect(
                ray: getWorldMatrixAt(index: i).inverse.act(ray),
                intersections: &geometryIntersections
            )
            let postCount = geometryIntersections.count

            for i in preCount ..< postCount {
                instanceIntersections.append(i)
            }
        }

        var results = [RaycastResult]()
        for (instance, intersection) in zip(instanceIntersections, geometryIntersections) {
            let raycastResult = RaycastResult(
                barycentricCoordinates: intersection.barycentricCoordinates,
                distance: intersection.distance,
                normal: intersection.normal,
                position: simd_make_float3(getWorldMatrixAt(index: instance) * simd_make_float4(intersection.position, 1.0)),
                primitiveIndex: intersection.primitiveIndex,
                object: self,
                submesh: nil,
                instance: instance
            )

            if options.first {
                intersections.append(raycastResult)
                return true
            }
            else {
                results.append(raycastResult)
            }
        }

        intersections.append(contentsOf: results)

        if options.recursive {
            for child in children {
                if child.intersect(
                    ray: ray,
                    intersections: &intersections,
                    options: options
                ) && options.first {
                    return true
                }
            }
        }

        return results.count > 0
    }

    // MARK: - Deinit

    deinit {
        transformSubscriber?.cancel()
    }
}
