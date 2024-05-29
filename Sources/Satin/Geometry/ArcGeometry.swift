//
//  ArcGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/6/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

#if SWIFT_PACKAGE
import SatinCore
#endif

import simd

public final class ArcGeometry: SatinGeometry {
    public var innerRadius: Float {
        didSet {
            if oldValue != innerRadius {
                _updateGeometryData = true
            }
        }
    }

    public var outerRadius: Float {
        didSet {
            if oldValue != outerRadius {
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

    public var radialResolution: Int {
        didSet {
            if oldValue != radialResolution {
                _updateGeometryData = true
            }
        }
    }

    public init(radius: (inner: Float, outer: Float), angle: (start: Float, end: Float), res: (angular: Int, radial: Int)) {
        self.innerRadius = radius.inner
        self.outerRadius = radius.outer
        self.startAngle = angle.start
        self.endAngle = angle.end
        self.angularResolution = res.angular
        self.radialResolution = res.radial

        super.init()
    }

    override public func generateGeometryData() -> GeometryData {
        generateArcGeometryData(
            innerRadius,
            outerRadius,
            startAngle,
            endAngle,
            Int32(angularResolution),
            Int32(radialResolution)
        )
    }
}
