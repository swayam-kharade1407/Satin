//
//  CircleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/6/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

#if SWIFT_PACKAGE
import SatinCore
#endif

public final class CircleGeometry: SatinGeometry {
    public var radius: Float = 1 {
        didSet {
            if oldValue != radius {
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

    public init(radius: Float) {
        self.radius = radius
        super.init()
    }

    public init(radius: Float, angularResolution: Int) {
        self.radius = radius
        self.angularResolution = angularResolution
        super.init()
    }

    public init(radius: Float, angularResolution: Int, radialResolution: Int) {
        self.radius = radius
        self.angularResolution = angularResolution
        self.radialResolution = radialResolution
        super.init()
    }

    public override func generateGeometryData() -> GeometryData {
        generateCircleGeometryData(radius, Int32(angularResolution), Int32(radialResolution))
    }
}
