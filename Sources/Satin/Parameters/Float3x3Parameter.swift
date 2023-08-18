//
//  File.swift
//
//
//  Created by Reza Ali on 4/19/22.
//

import Foundation
import simd

public final class Float3x3Parameter: GenericParameter<simd_float3x3> {
    override public var type: ParameterType { .float3x3 }
}
