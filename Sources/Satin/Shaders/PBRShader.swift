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
        for (index, sampler) in samplers where sampler != nil {
            results.append(sampler!.shaderInjection(index: index))
        }
        return results
    }

    open override func getDefines() -> [String : NSObject] {
        var results = super.getDefines()
        if !maps.isEmpty { results["HAS_MAPS"] = NSString(string: "true") }
        for map in maps { results[map.key.shaderDefine] = NSString(string: "true") }
        results[tonemapping.shaderDefine] = NSString(string: "true")
        return results
    }
}
