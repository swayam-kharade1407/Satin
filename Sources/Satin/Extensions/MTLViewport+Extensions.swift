//
//  MTLViewport+Extensions.swift
//
//
//  Created by Reza Ali on 2/3/24.
//

import Foundation
import Metal
import simd

public extension MTLViewport {
    var float4: simd_float4 {
        simd_make_float4(Float(self.originX), Float(self.originY), Float(self.width), Float(self.height))
    }
}
