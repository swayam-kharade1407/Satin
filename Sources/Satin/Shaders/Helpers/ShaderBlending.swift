//
//  ShaderBlending.swift
//
//
//  Created by Reza Ali on 6/14/23.
//

import Foundation
import Metal

public struct ShaderBlending: Hashable {
    public var type: Blending = .disabled
    public var sourceRGBBlendFactor: MTLBlendFactor = .sourceAlpha
    public var sourceAlphaBlendFactor: MTLBlendFactor = .sourceAlpha
    public var destinationRGBBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha
    public var destinationAlphaBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha
    public var rgbBlendOperation: MTLBlendOperation = .add
    public var alphaBlendOperation: MTLBlendOperation = .add
}

extension ShaderBlending: Equatable {
    public static func == (lhs: ShaderBlending, rhs: ShaderBlending) -> Bool {
        if lhs.type == .custom && rhs.type == .custom {
            return lhs.sourceRGBBlendFactor == rhs.sourceRGBBlendFactor && lhs.sourceAlphaBlendFactor == rhs.sourceAlphaBlendFactor &&
                lhs.destinationRGBBlendFactor == rhs.destinationRGBBlendFactor && lhs.destinationAlphaBlendFactor == rhs.destinationAlphaBlendFactor &&
                lhs.rgbBlendOperation == rhs.rgbBlendOperation && lhs.alphaBlendOperation == rhs.alphaBlendOperation
        }
        else {
            return lhs.type == rhs.type
        }
    }
}
