//
//  SDFTextGeometry.swift
//
//
//  Created by Reza Ali on 12/30/23.
//

import Foundation
import simd

public final class TextGeometry: Geometry {
    public var font: FontAtlas {
        didSet {
            _updateData = true
        }
    }

    public var text: String {
        didSet {
            if text != oldValue {
                _updateData = true
            }
        }
    }

    private var _updateData: Bool = true

    private var positions: [simd_float3] = []
    private let positionBuffer = Float3BufferAttribute(defaultValue: .zero, data: [])

    private var texcoords: [simd_float2] = []
    private let texcoordBuffer = Float2BufferAttribute(defaultValue: .zero, data: [])

    private var indices: [UInt32] = []
    private let indexElementBuffer =  ElementBuffer(type: .uint32, data: nil, count: 0, source: nil)

    public init(text: String, font: FontAtlas) {
        self.text = text
        self.font = font
        super.init()

        addAttribute(positionBuffer, for: .Position)
        addAttribute(texcoordBuffer, for: .Texcoord)
        setElements(indexElementBuffer)

        updateData()
    }

    public func updateData() {
        var totalAdvance: Float = 0

        for char in text {
            if let character = font.characters[String(char)] {
                totalAdvance += character.advance
            }
        }

        // Center the text at the origin
        var x = -totalAdvance / 2.0
        let y: Float = -Float(font.size) / 2.0

        let fontWidth = Float(font.width)
        let fontHeight = Float(font.height)

        indices.removeAll(keepingCapacity: true)
        texcoords.removeAll(keepingCapacity: true)
        positions.removeAll(keepingCapacity: true)

        var index: UInt32 = 0

        for char in text {
            guard let c = font.characters[String(char)] else { continue }
            if char.isWhitespace {
                x += c.advance
            }
            else {
                // p0 --- p1
                // | \     |
                // |   \   |
                // |     \ |
                // p2 --- p3

                let leftX = x - c.originX
                let rightX = leftX + c.width

                let botY = y
                let topY = botY + c.height

                let leftU = c.x / fontWidth
                let rightU = leftU + (c.width / fontWidth)

                let topV = c.y / fontHeight
                let botV = topV + (c.height / fontHeight)

                let x0 = leftX
                let y0 = topY
                let u0 = leftU
                let v0 = topV

                let x1 = rightX
                let y1 = topY
                let u1 = rightU
                let v1 = topV

                let x2 = leftX
                let y2 = botY
                let u2 = leftU
                let v2 = botV

                let x3 = rightX
                let y3 = botY
                let u3 = rightU
                let v3 = botV

                let p0 = simd_make_float3(x0, y0, 0.0);
                let t0 = simd_make_float2(u0, v0);
                let p1 = simd_make_float3(x1, y1, 0.0);
                let t1 = simd_make_float2(u1, v1);
                let p2 = simd_make_float3(x2, y2, 0.0);
                let t2 = simd_make_float2(u2, v2);
                let p3 = simd_make_float3(x3, y3, 0.0);
                let t3 = simd_make_float2(u3, v3);

                positions.append(contentsOf: [p0, p1, p2, p3])
                texcoords.append(contentsOf: [t0, t1, t2, t3])

                let i0 = index
                let i1 = index + 1
                let i2 = index + 2
                let i3 = index + 3

                indices.append(contentsOf: [i0, i2, i3, i0, i3, i1])

                index += 4

                x += c.advance
            }
        }

        texcoordBuffer.data = texcoords
        positionBuffer.data = positions
        indexElementBuffer.updateData(data: &indices, count: indices.count, source: indices)

        _updateData = false
    }

    override public func setup() {
        if _updateData { updateData() }
        super.setup()
    }

    override public func update() {
        if _updateData { updateData() }
        super.update()
    }
}
