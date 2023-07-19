//
//  PointGeometry.swift
//  Satin
//
//  Created by Reza Ali on 10/9/19.
//

import SatinCore

public final class PointGeometry: Geometry {
    public var vertexData: [Vertex] = [Vertex(
        position: [0.0, 0.0, 0.0, 1.0],
        normal: [0.0, 0.0, 1.0],
        uv: [0.0, 0.0]
    )] {
        didSet {
            _updateGeometry = true
        }
    }

    var _updateGeometry = true

    public init() {
        super.init(primitiveType: .point)
        setupGeometry()
    }

    override public func update(camera: Camera, viewport: simd_float4) {
        if _updateGeometry { setupGeometry() }
        super.update(camera: camera, viewport: viewport)
    }

    func setupGeometry() {
        removeAttributes()

        let interleavedBuffer = InterleavedBuffer(index: .Vertices, data: &vertexData, stride: MemoryLayout<Vertex>.size, count: vertexData.count, source: vertexData)

        var offset = 0
        addAttribute(Float4InterleavedBufferAttribute(buffer: interleavedBuffer, offset: offset), for: .Position)
        offset += MemoryLayout<Float>.size * 4
        addAttribute(Float3InterleavedBufferAttribute(buffer: interleavedBuffer, offset: offset), for: .Normal)
        offset += MemoryLayout<Float>.size * 4
        addAttribute(Float2InterleavedBufferAttribute(buffer: interleavedBuffer, offset: offset), for: .Texcoord)

        _updateGeometry = false
    }
}
