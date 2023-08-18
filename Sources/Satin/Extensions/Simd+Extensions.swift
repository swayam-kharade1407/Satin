//
//  Simd+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 9/14/19.
//

import Metal
import simd
import SatinCore

extension MTLPackedFloat3: Equatable {
    public static func == (lhs: _MTLPackedFloat3, rhs: _MTLPackedFloat3) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}

extension MTLPackedFloat3: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let x = try values.decode(Float.self, forKey: .x)
        let y = try values.decode(Float.self, forKey: .y)
        let z = try values.decode(Float.self, forKey: .z)
        self.init()
        self.x = x
        self.y = y
        self.z = z
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(z, forKey: .z)
    }

    private enum CodingKeys: String, CodingKey {
        case x, y, z
    }
}

extension simd_quatf: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let x = try values.decode(Float.self, forKey: .x)
        let y = try values.decode(Float.self, forKey: .y)
        let z = try values.decode(Float.self, forKey: .z)
        let w = try values.decode(Float.self, forKey: .w)
        self.init(ix: x, iy: y, iz: z, r: w)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(vector.x, forKey: .x)
        try container.encode(vector.y, forKey: .y)
        try container.encode(vector.z, forKey: .z)
        try container.encode(vector.w, forKey: .w)
    }

    private enum CodingKeys: String, CodingKey {
        case x, y, z, w
    }
}

extension simd_float4x4: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let columns = try values.decode([simd_float4].self, forKey: .columns)
        self.init(columns: (columns[0], columns[1], columns[2], columns[3]))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode([columns.0, columns.1, columns.2, columns.3], forKey: .columns)
    }

    private enum CodingKeys: String, CodingKey {
        case columns
    }
}

public extension simd_float4x4 {
    func act(_ ray: Ray) -> Ray {
        let transformedOrigin = simd_make_float3(self * simd_make_float4(ray.origin, 1.0))
        let transformedDirection = simd_make_float3(self * simd_make_float4(ray.direction))
        return Ray(origin: transformedOrigin, direction: simd_normalize(transformedDirection))
    }
}

extension simd_float3x3: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let columns = try values.decode([simd_float3].self, forKey: .columns)
        self.init(columns: (columns[0], columns[1], columns[2]))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode([columns.0, columns.1, columns.2], forKey: .columns)
    }

    private enum CodingKeys: String, CodingKey {
        case columns
    }
}

extension simd_float2x2: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let columns = try values.decode([simd_float2].self, forKey: .columns)
        self.init(columns: (columns[0], columns[1]))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode([columns.0, columns.1], forKey: .columns)
    }

    private enum CodingKeys: String, CodingKey {
        case columns
    }
}
