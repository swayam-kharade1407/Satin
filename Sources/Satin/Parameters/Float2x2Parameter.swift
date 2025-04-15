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

    override public init(_ label: String, _ value: simd_float2x2, _ controlType: ControlType = .none) {
        super.init(label, value, controlType)
    }

    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case value
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let controlType = try container.decode(ControlType.self, forKey: .controlType)
        let label = try container.decode(String.self, forKey: .label)
        let value = try container.decode(simd_float2x2.self, forKey: .value)
        super.init(label, value, controlType)
    }

    override public func clone() -> any Parameter {
        Float2x2Parameter(label, value, controlType)
    }
}
