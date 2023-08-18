//
//  Float2x2Parameter.swift
//
//
//  Created by Reza Ali on 8/3/22.
//

import Foundation
import simd

public final class Float2x2Parameter: GenericParameter<simd_float2x2> {
    override public var type: ParameterType { .float2x2 }
}
