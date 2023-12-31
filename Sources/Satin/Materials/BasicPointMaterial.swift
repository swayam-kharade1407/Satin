//
//  BasicPointMaterial.swift
//  Satin
//
//  Created by Reza Ali on 6/28/20.
//

import Metal
import simd

public final class BasicPointMaterial: Material {
    public var color: simd_float4 {
        get {
            (get("Color") as! Float4Parameter).value
        }
        set {
            set("Color", newValue)
        }
    }

    public var pointSize: Float {
        get {
            (get("Point Size") as! FloatParameter).value
        }
        set {
            set("Point Size", newValue)
        }
    }

    public init(color: simd_float4 = simd_float4(repeating: 1.0), size: Float = 2.0, blending: Blending = .alpha) {
        super.init()
        self.blending = blending
        set("Color", color)
        set("Point Size", size)
    }

    public required init() {
        super.init()
        blending = .alpha
        set("Color", [1, 1, 1, 1])
        set("Point Size", 2.0)
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
