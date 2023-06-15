//
//  ShaderBlending.swift
//  
//
//  Created by Reza Ali on 6/14/23.
//

import Foundation
import Metal

public struct ShaderBlending: Equatable, Hashable {
    public var type: Blending = .disabled
    public var sourceRGBBlendFactor: MTLBlendFactor = .sourceAlpha
    public var sourceAlphaBlendFactor: MTLBlendFactor = .sourceAlpha
    public var destinationRGBBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha
    public var destinationAlphaBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha
    public var rgbBlendOperation: MTLBlendOperation = .add
    public var alphaBlendOperation: MTLBlendOperation = .add
}
