//
//  Blending.swift
//  
//
//  Created by Reza Ali on 3/17/23.
//

import Foundation
import Metal

public enum Blending: Codable {
    case disabled
    case alpha
    case additive
    case subtract
    case custom
}
