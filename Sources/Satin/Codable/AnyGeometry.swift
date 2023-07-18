//
//  AnyGeometry.swift
//  
//
//  Created by Reza Ali on 7/17/23.
//

//import Foundation
//
//public enum GeometryType: String, Codable {
//    case base, arc, box, capsule, circle, cone, cylinder, extrudedRoundedRect, extrudedText, icosphere, octasphere, parametric, plane, quad, ro
//
//    var metaType: Geometry.Type {
//        switch self {
//        }
//    }
//}
//
//open class AnyGeometry: Codable {
//    public var type: GeometryType
//    public var geometry: Geometry
//
//    // Important: the ordering below is dependent of inheritance hierarchy
//
//    public init(_ material: Material) {
//        self.material = material
//
//        if material is MatCapMaterial {
//            type = .matcap
//        } else if material is BasicTextureMaterial {
//            type = .basictexture
//        } else if material is BasicDiffuseMaterial {
//            type = .basicdiffuse
//        } else if material is BasicColorMaterial {
//            type = .basiccolor
//        } else if material is BasicPointMaterial {
//            type = .basicpoint
//        } else if material is DepthMaterial {
//            type = .depth
//        } else if material is NormalColorMaterial {
//            type = .normal
//        } else if material is SkyboxMaterial {
//            type = .skybox
//        } else if material is PhysicalMaterial {
//            type = .physical
//        } else if material is StandardMaterial {
//            type = .standard
//        }  else if material is UvColorMaterial {
//            type = .uvcolor
//        } else if material is ShadowMaterial {
//            type = .shadow
//        } else {
//            type = .base
//        }
//    }
//
//    private enum CodingKeys: CodingKey {
//        case type, material
//    }
//
//    public required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        type = try container.decode(MaterialType.self, forKey: .type)
//        material = try type.metaType.init(from: container.superDecoder(forKey: .material))
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(type, forKey: .type)
//        try material.encode(to: container.superEncoder(forKey: .material))
//    }
//}
