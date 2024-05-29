//
//  TubeGeometry.swift
//  Satin
//
//  Created by Reza Ali on 3/15/22.
//

#if SWIFT_PACKAGE
import SatinCore
#endif

public final class TubeGeometry: SatinGeometry {
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

    public var startAngle: Float {
        didSet {
            if oldValue != startAngle {
                _updateGeometryData = true
            }
        }
    }

    public var endAngle: Float {
        didSet {
            if oldValue != endAngle {
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

    public init(radius: Float, height: Float, startAngle: Float, endAngle: Float, angularResolution: Int, verticalResolution: Int) {
        self.radius = radius
        self.height = height
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.angularResolution = angularResolution
        self.verticalResolution = verticalResolution
        super.init()
    }

    override public func generateGeometryData() -> GeometryData {
        generateTubeGeometryData(radius, height, startAngle, endAngle, Int32(angularResolution), Int32(verticalResolution))
    }
}
