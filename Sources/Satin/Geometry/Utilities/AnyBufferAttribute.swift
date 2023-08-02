//
//  AnyBufferAttribute.swift
//  
//
//  Created by Reza Ali on 8/2/23.
//

import Foundation

open class AnyBufferAttribute: Codable {
    public var attribute: any BufferAttribute

    public init(_ attribute: any BufferAttribute) {
        self.attribute = attribute
    }

    private enum CodingKeys: CodingKey {
        case type, attribute
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(AttributeType.self, forKey: .type)
        attribute = try type.metatype.init(from: container.superDecoder(forKey: .attribute))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(attribute.type, forKey: .type)
        try attribute.encode(to: container.superEncoder(forKey: .attribute))
    }
}
