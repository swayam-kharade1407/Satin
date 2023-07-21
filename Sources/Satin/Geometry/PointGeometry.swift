//
//  PointGeometry.swift
//  Satin
//
//  Created by Reza Ali on 10/9/19.
//

import Foundation
import Metal
import SatinCore

public final class PointGeometry: Geometry {
    public var data: [simd_float3] {
        didSet {
            pointBufferAttribute.data = data
        }
    }

    let pointBufferAttribute = Float3BufferAttribute(data: [])

    public init(data: [simd_float3] = [.zero]) {
        self.data = data
        super.init(primitiveType: .point)
        addAttribute(pointBufferAttribute, for: .Position)
        pointBufferAttribute.data = data
    }
}
