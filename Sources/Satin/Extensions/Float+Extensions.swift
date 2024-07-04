//
//  Float+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 7/4/24.
//

import Foundation

extension Float {
    var toDegrees: Float {
        radToDeg(self)
    }

    var toRadians: Float {
        degToRad(self)
    }
}
