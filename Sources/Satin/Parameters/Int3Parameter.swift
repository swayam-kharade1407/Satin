//
//  Int3Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/10/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

public final class Int3Parameter: GenericParameterWithMinMax<simd_int3> {
    override public var type: ParameterType { .int3 }

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .none) {
        self.init(label, value, .zero, .one, controlType)
    }
}
