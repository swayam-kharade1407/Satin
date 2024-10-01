//
//  Int4Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/10/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

public final class Int4Parameter: GenericParameterWithMinMax<simd_int4> {
    override public var type: ParameterType { .int4 }

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .none) {
        self.init(label, value, .zero, .one, controlType)
    }

    public override func clone() -> any Parameter {
        Int4Parameter(label, value, min, max, controlType)
    }
}
