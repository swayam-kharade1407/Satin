//
//  SatinGeometry.swift
//  
//
//  Created by Reza Ali on 7/17/23.
//

import Foundation
import SatinCore

open class SatinGeometry: Geometry {
    public internal(set) var geometryData: GeometryData = createGeometryData()

    public var _updateGeometryData: Bool = true

    public init() {
        super.init()
        setupGeometry()
    }

    deinit {
        freeGeometryData(&geometryData)
    }

    public override func update(camera: Camera, viewport: simd_float4) {
        if _updateGeometryData {
            setupGeometry()
        }

        super.update(camera: camera, viewport: viewport)
    }

    open func generateGeometryData() -> GeometryData {
        createGeometryData()
    }

    open func setupGeometry() {
        freeGeometryData(&geometryData)
        setFrom(geometryData: generateGeometryData())
        _updateGeometryData = false
    }

    internal func setFrom(geometryData: GeometryData) {
        self.geometryData = geometryData

        if let vertexData = geometryData.vertexData {
            let vertexCount = Int(geometryData.vertexCount)
            let interleavedBuffer = InterleavedBuffer(
                index: .Vertices,
                data: vertexData,
                stride: MemoryLayout<Vertex>.size,
                count: vertexCount,
                source: geometryData
            )

            if geometryData.indexCount > 0, let indexData = geometryData.indexData {
                self.elementBuffer = ElementBuffer(
                    type: .uint32,
                    data: indexData,
                    count: Int(geometryData.indexCount) * 3,
                    source: geometryData
                )
            } else {
                self.elementBuffer = nil
            }

            var offset = 0
            addAttribute(Float4InterleavedBufferAttribute(buffer: interleavedBuffer, offset: offset), for: .Position)
            offset += MemoryLayout<Float>.size * 4
            addAttribute(Float3InterleavedBufferAttribute(buffer: interleavedBuffer, offset: offset), for: .Normal)
            offset += MemoryLayout<Float>.size * 4
            addAttribute(Float2InterleavedBufferAttribute(buffer: interleavedBuffer, offset: offset), for: .Texcoord)
        }
    }
}
