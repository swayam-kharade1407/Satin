//
//  PhysicalShader.swift
//  Satin
//
//  Created by Reza Ali on 12/9/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

open class PhysicalShader: PBRShader {
    override open func getDefines() -> [ShaderDefine] {
        var results = super.getDefines()
        results.append(ShaderDefine(key: "HAS_CLEARCOAT", value: NSString(string: "true")))
        results.append(ShaderDefine(key: "HAS_SUBSURFACE", value: NSString(string: "true")))
        results.append(ShaderDefine(key: "HAS_SPECULAR_TINT", value: NSString(string: "true")))
        results.append(ShaderDefine(key: "HAS_SHEEN", value: NSString(string: "true")))
        results.append(ShaderDefine(key: "HAS_TRANSMISSION", value: NSString(string: "true")))
        results.append(ShaderDefine(key: "HAS_ANISOTROPIC", value: NSString(string: "true")))
        return results
    }
}
