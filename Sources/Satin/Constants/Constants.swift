//
//  Defines.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import ModelIO
import simd

public let maxBuffersInFlight = 3

public let worldForwardDirection = simd_make_float3(0, 0, 1)
public let worldUpDirection = simd_make_float3(0, 1, 0)
public let worldRightDirection = simd_make_float3(1, 0, 0)

public let MDLMaterialSemanticToSatinPBRTextureTypeMap: [MDLMaterialSemantic: PBRTextureType] = [
    .baseColor: .baseColor,
    .subsurface: .subsurface,
    .metallic: .metallic,
    .roughness: .roughness,
    .objectSpaceNormal: .normal,
    .emission: .emissive,
    .specular: .specular,
    .specularTint: .specularTint,
    .sheen: .sheen,
    .sheenTint: .sheenTint,
    .clearcoat: .clearcoat,
    .clearcoatGloss: .clearcoatGloss,
    .anisotropic: .anisotropic,
    .anisotropicRotation: .anisotropicAngle,
    .bump: .bump,
    .displacement: .displacement,
    .opacity: .alpha,
    .materialIndexOfRefraction: .ior,
    .ambientOcclusion: .occlusion,
]
