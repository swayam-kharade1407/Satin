//
//  Float4x4Parameter.swift
//
//
//  Created by Reza Ali on 4/19/22.
//

import Foundation
import simd

public final class Float4x4Parameter: GenericParameter<simd_float4x4> {
    override public var type: ParameterType { .float4x4 }
}
