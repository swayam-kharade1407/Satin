//
//  OctaSphereGeometry.swift
//  Satin
//
//  Created by Reza Ali on 3/15/22.
//

import SatinCore

public final class OctaSphereGeometry: SatinGeometry {
    public var radius: Float = 1 {
        didSet {
            if oldValue != radius {
                _updateGeometryData = true
            }
        }
    }

    public var resolution: Int = 1 {
        didSet {
            if oldValue != resolution {
                _updateGeometryData = true
            }
        }
    }


    public init(radius: Float, resolution: Int) {
        self.radius = radius
        self.resolution = resolution
        super.init()
    }

    public override func generateGeometryData() -> GeometryData {
        generateOctaSphereGeometryData(radius, Int32(resolution))
    }
}
