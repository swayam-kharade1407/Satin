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

    public override init(_ label: String, _ value: simd_float4x4, _ controlType: ControlType = .none) {
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
        let value = try container.decode(simd_float4x4.self, forKey: .value)
        super.init(label, value, controlType)
    }
}
