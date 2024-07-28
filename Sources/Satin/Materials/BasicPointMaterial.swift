//
//  BasicPointMaterial.swift
//  Satin
//
//  Created by Reza Ali on 6/28/20.
//

import Metal
import simd

open class BasicPointMaterial: Material {
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

    public var contentScale: Float = 1.0 {
        didSet {
            if contentScale != oldValue {
                set("Content Scale", contentScale)
            }
        }
    }

    public init(color: simd_float4, size: Float, blending: Blending = .alpha, depthWriteEnabled: Bool = true, depthCompareFunction: MTLCompareFunction = .greaterEqual) {
        super.init()

        self.blending = blending
        self.depthWriteEnabled = depthWriteEnabled
        self.depthCompareFunction = depthCompareFunction

        set("Color", color)
        set("Point Size", size)
        set("Content Scale", contentScale)
    }

    public required init() {
        super.init()
        blending = .alpha
        set("Color", simd_float4.one)
        set("Point Size", 2.0)
        set("Content Scale", contentScale)
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
