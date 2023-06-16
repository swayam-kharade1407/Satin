//
//  SkyboxShader.swift
//
//
//  Created by Reza Ali on 4/10/23.
//

import Foundation
import Metal

open class SkyboxShader: SourceShader {
    open var tonemapping: Tonemapping = .aces {
        didSet {
            if oldValue != tonemapping {
                definesNeedsUpdate = true
            }
        }
    }

    open override func getDefines() -> [ShaderDefine] {
        var results = super.getDefines()
        results.append(ShaderDefine(key: tonemapping.shaderDefine, value: NSString(string: "true")))
        return results
    }
}
