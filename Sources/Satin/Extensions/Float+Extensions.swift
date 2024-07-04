//
//  Float+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 7/4/24.
//

import Foundation

#if SWIFT_PACKAGE
import SatinCore
#endif


extension Float {
    var toDegrees: Float {
        radToDeg(self)
    }

    var toRadians: Float {
        degToRad(self)
    }
}
