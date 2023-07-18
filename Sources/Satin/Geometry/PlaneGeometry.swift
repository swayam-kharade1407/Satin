//
//  SolidPlaneGeometry.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import SatinCore

public final class PlaneGeometry: SatinGeometry {
    public enum PlaneOrientation: Int32 {
        case xy = 0 // points in +z direction
        case yx = 1 // points in -z direction
        case xz = 2 // points in -y direction
        case zx = 3 // points in +y direction
        case yz = 4 // points in +x direction
        case zy = 5 // points in -x direction
    }


    var width: Float {
        get {
            size.x
        }
        set {
            size.x = newValue
        }
    }

    var height: Float {
        get {
            size.y
        }
        set {
            size.y = newValue
        }
    }

    var size: simd_float2 = .init(repeating: 2) {
        didSet {
            if oldValue != size {
                _updateGeometryData = true
            }
        }
    }

    var resolution: simd_int2 = .init(repeating: 1)  {
        didSet {
            if oldValue != resolution {
                _updateGeometryData = true
            }
        }
    }

    var orientation: PlaneOrientation = .xy  {
        didSet {
            if oldValue != orientation {
                _updateGeometryData = true
            }
        }
    }

    var centered: Bool = true  {
        didSet {
            if oldValue != centered {
                _updateGeometryData = true
            }
        }
    }

    public init(size: Float = 2, resolution: Int = 1, orientation: PlaneOrientation = .xy, centered: Bool = true) {
        self.size = .init(repeating: size)
        self.resolution = .init(repeating: Int32(resolution))
        self.orientation = orientation
        self.centered = centered
        super.init()
    }

    public init(width: Float = 2, height: Float = 2, widthResolution: Int = 1, heightResolution: Int = 1, orientation: PlaneOrientation = .xy, centered: Bool = true) {
        self.size = simd_make_float2(width, height)
        self.resolution = simd_make_int2(Int32(widthResolution), Int32(heightResolution))
        self.orientation = orientation
        self.centered = centered
        super.init()
    }

    public override func generateGeometryData() -> GeometryData {
        generatePlaneGeometryData(size.x, size.y, resolution.x, resolution.y, orientation.rawValue, centered)
    }
}
