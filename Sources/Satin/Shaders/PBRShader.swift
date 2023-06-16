//
//  PBRShader.swift
//  Satin
//
//  Created by Reza Ali on 12/9/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import Metal

open class PBRShader: SourceShader {
    open var maps: [PBRTextureIndex: MTLTexture?] = [:] {
        didSet {
            if oldValue.keys != maps.keys {
                definesNeedsUpdate = true
            }
        }
    }

    open var samplers: [PBRTextureIndex: MTLSamplerDescriptor?] = [:] {
        didSet {
            if oldValue.keys != samplers.keys {
                constantsNeedsUpdate = true
            }
        }
    }

    open var tonemapping: Tonemapping = .aces {
        didSet {
            if oldValue != tonemapping {
                definesNeedsUpdate = true
            }
        }
    }

    open override func getConstants() -> [String] {
        var results = super.getConstants()
        for pbrTexIndex in PBRTextureIndex.allCases {

            if let sampler = samplers[pbrTexIndex], let descriptor = sampler {
                results.append(descriptor.shaderInjection(index: pbrTexIndex))
            }

        }
        return results
    }

    open override func getDefines() -> [ShaderDefine] {
        var results = super.getDefines()

        if !maps.isEmpty { results.append(ShaderDefine(key: "HAS_MAPS", value: NSString(string: "true"))) }

        for pbrTexIndex in PBRTextureIndex.allCases where maps[pbrTexIndex] != nil {
            results.append(ShaderDefine(key: pbrTexIndex.shaderDefine, value: NSString(string: "true")))
        }

        results.append(ShaderDefine(key: tonemapping.shaderDefine, value: NSString(string: "true")))
        return results
    }
}
