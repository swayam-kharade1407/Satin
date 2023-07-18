//
//  CapsuleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/11/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd
import SatinCore

public final class CapsuleGeometry: SatinGeometry {
    public enum Axis: Int32 {
        case x = 0
        case y = 1
        case z = 2
    }

    public var radius: Float {
        didSet {
            if oldValue != radius {
                _updateGeometryData = true
            }
        }
    }

    public var height: Float {
        didSet {
            if oldValue != height {
                _updateGeometryData = true
            }
        }
    }

    public var angularResolution: Int = 60 {
        didSet {
            if oldValue != angularResolution {
                _updateGeometryData = true
            }
        }
    }

    public var radialResolution: Int = 30 {
        didSet {
            if oldValue != radialResolution {
                _updateGeometryData = true
            }
        }
    }

    public var verticalResolution: Int = 1 {
        didSet {
            if oldValue != verticalResolution {
                _updateGeometryData = true
            }
        }
    }

    public var axis: Axis = .y {
        didSet {
            if oldValue != axis {
                _updateGeometryData = true
            }
        }
    }

    public init(radius: Float, height: Float, axis: Axis = .y) {
        self.radius = radius
        self.height = height
        self.axis = axis

        super.init()
    }

    public init(radius: Float, height: Float, angularResolution: Int = 60, radialResolution: Int = 30, verticalResolution: Int = 1, axis: Axis = .y) {
        self.radius = radius
        self.height = height
        self.angularResolution = angularResolution
        self.radialResolution = radialResolution
        self.verticalResolution = verticalResolution
        self.axis = axis

        super.init()
    }

    public override func generateGeometryData() -> GeometryData {
        generateCapsuleGeometryData(radius, height, Int32(angularResolution), Int32(radialResolution), Int32(verticalResolution), axis.rawValue)
    }
}
