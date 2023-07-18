//
//  CylinderGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/8/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import SatinCore

public final class CylinderGeometry: SatinGeometry {
    public var radius: Float = 1.0 {
        didSet {
            if oldValue != radius {
                _updateGeometryData = true
            }
        }
    }

    public var height: Float = 2.0 {
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

    public var radialResolution: Int = 1 {
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

    public init(radius: Float, height: Float, angularResolution: Int = 60, radialResolution: Int = 1, verticalResolution: Int = 1) {
        self.radius = radius
        self.height = height
        self.angularResolution = angularResolution
        self.radialResolution = radialResolution
        self.verticalResolution = verticalResolution
        super.init()
    }

    override public func generateGeometryData() -> GeometryData {
        generateCylinderGeometryData(radius, height, Int32(angularResolution), Int32(radialResolution), Int32(verticalResolution))
    }
}
