//
//  MTLVertexFormat+Extensions.swift
//  
//
//  Created by Reza Ali on 7/13/23.
//

import Metal

extension MTLVertexFormat {
    var dataType: String? {
        switch self {
            case .invalid:
                return nil
            case .uchar2:
                return "uchar2"
            case .uchar3:
                return "uchar3"
            case .uchar4:
                return "uchar4"
            case .char2:
                return "char2"
            case .char3:
                return "char3"
            case .char4:
                return "char4"
            case .uchar2Normalized:
                return "uchar2"
            case .uchar3Normalized:
                return "uchar3"
            case .uchar4Normalized:
                return "uchar4"
            case .char2Normalized:
                return "uchar2"
            case .char3Normalized:
                return "char3"
            case .char4Normalized:
                return "char4"
            case .ushort2:
                return "ushort2"
            case .ushort3:
                return "ushort3"
            case .ushort4:
                return "ushort4"
            case .short2:
                return "short2"
            case .short3:
                return "short3"
            case .short4:
                return "short4"
            case .ushort2Normalized:
                return "ushort2"
            case .ushort3Normalized:
                return "ushort3"
            case .ushort4Normalized:
                return "ushort4"
            case .short2Normalized:
                return "short2"
            case .short3Normalized:
                return "short3"
            case .short4Normalized:
                return "short4"
            case .half2:
                return "half2"
            case .half3:
                return "half3"
            case .half4:
                return "half4"
            case .float:
                return "float"
            case .float2:
                return "float2"
            case .float3:
                return "float3"
            case .float4:
                return "float4"
            case .int:
                return "int"
            case .int2:
                return "int2"
            case .int3:
                return "int3"
            case .int4:
                return "int4"
            case .uint:
                return "uint"
            case .uint2:
                return "uint2"
            case .uint3:
                return "uint3"
            case .uint4:
                return "uint4"
            case .int1010102Normalized:
                return "float"
            case .uint1010102Normalized:
                return "float"
            case .uchar4Normalized_bgra:
                return "uchar4"
            case .uchar:
                return "uchar"
            case .char:
                return "char"
            case .ucharNormalized:
                return "uchar"
            case .charNormalized:
                return "char"
            case .ushort:
                return "ushort"
            case .short:
                return "short"
            case .ushortNormalized:
                return "ushort"
            case .shortNormalized:
                return "short"
            case .half:
                return "half"
            @unknown default:
                fatalError("Unknown vertex format: \(self)")
        }
    }
}
