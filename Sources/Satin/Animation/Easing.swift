//
//  Easing.swift
//  Juicer
//
//  Created by Reza Ali on 7/24/20.
//

import Foundation

public enum Easing {
    case linear
    case smoothstep
    case inSine
    case outSine
    case inOutSine
    case inQuad
    case outQuad
    case inOutQuad
    case inCubic
    case outCubic
    case inOutCubic
    case inQuart
    case outQuart
    case inOutQuart
    case inQuint
    case outQuint
    case inOutQuint
    case inExpo
    case outExpo
    case inOutExpo
    case inCirc
    case outCirc
    case inOutCirc
    case inBack
    case outBack
    case inOutBack
    case inElastic
    case outElastic
    case inOutElastic
    case inBounce
    case outBounce
    case inOutBounce

    public var function: (Double) -> Double {
        switch self {
            case .linear:
                easeLinear
            case .smoothstep:
                easeSmoothstep
            case .inSine:
                easeInSine
            case .outSine:
                easeOutSine
            case .inOutSine:
                easeInOutSine
            case .inQuad:
                easeInQuad
            case .outQuad:
                easeOutQuad
            case .inOutQuad:
                easeInOutQuad
            case .inCubic:
                easeInCubic
            case .outCubic:
                easeOutCubic
            case .inOutCubic:
                easeInOutCubic
            case .inQuart:
                easeInQuart
            case .outQuart:
                easeOutQuart
            case .inOutQuart:
                easeInOutQuart
            case .inQuint:
                easeInQuint
            case .outQuint:
                easeOutQuint
            case .inOutQuint:
                easeInOutQuint
            case .inExpo:
                easeInExpo
            case .outExpo:
                easeOutExpo
            case .inOutExpo:
                easeInOutExpo
            case .inCirc:
                easeInCirc
            case .outCirc:
                easeOutCirc
            case .inOutCirc:
                easeInOutCirc
            case .inBack:
                easeInBack
            case .outBack:
                easeOutBack
            case .inOutBack:
                easeInOutBack
            case .inElastic:
                easeInElastic
            case .outElastic:
                easeOutElastic
            case .inOutElastic:
                easeInOutElastic
            case .inBounce:
                easeInBounce
            case .outBounce:
                easeOutBounce
            case .inOutBounce:
                easeInOutBounce
        }
    }
}
