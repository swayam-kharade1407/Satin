//
//  MTLClearColor+Extensions.swift
//
//
//  Created by Reza Ali on 1/21/24.
//

import Metal
import simd

public extension MTLClearColor {
    init(_ color: simd_float4) {
        self.init(
            red: Double(color.x),
            green: Double(color.y),
            blue: Double(color.z),
            alpha: Double(color.w)
        )
    }
}
