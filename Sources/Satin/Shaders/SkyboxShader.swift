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
                setupDefines()
            }
        }
    }

    override open func setupDefines() {
        defines[tonemapping.shaderDefine] = NSString(string: "true")
    }
}
