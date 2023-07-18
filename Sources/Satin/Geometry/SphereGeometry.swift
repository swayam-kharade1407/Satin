//
//  SphereGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/1/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import SatinCore

public final class SphereGeometry: SatinGeometry {
    public var radius: Float {
        didSet {
            if oldValue != radius {
                _updateGeometryData = true
            }
        }
    }

    public var angularResolution: Int {
        didSet {
            if oldValue != angularResolution {
                _updateGeometryData = true
            }
        }
    }

    public var verticalResolution: Int {
        didSet {
            if oldValue != verticalResolution {
                _updateGeometryData = true
            }
        }
    }

    public init(radius: Float, angularResolution: Int, verticalResolution: Int) {
        self.radius = radius
        self.angularResolution = angularResolution
        self.verticalResolution = verticalResolution
        super.init()
    }

    override public func generateGeometryData() -> GeometryData {
        generateSphereGeometryData(radius, Int32(angularResolution), Int32(verticalResolution))
    }
}
