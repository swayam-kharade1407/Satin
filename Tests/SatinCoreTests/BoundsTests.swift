//
//  BoundsTests.swift
//
//
//  Created by Taylor Holliday on 8/3/22.
//

#if SWIFT_PACKAGE
import SatinCore
#else
import Satin
#endif

import simd
import XCTest


class BoundsTests: XCTestCase {
    func testComputeBoundsFromVertices() {
        var vertices0: [SatinVertex] = []
        XCTAssertEqual(computeBoundsFromVertices(&vertices0, 0), createBounds())

        var vertices1 = [
            SatinVertex(position: .init(0, 0, 0), normal: .init(0, 0, 0), uv: .init(0, 0))
        ]
        XCTAssertEqual(computeBoundsFromVertices(&vertices1, 1), Bounds(min: .init(0, 0, 0), max: .init(0, 0, 0)))

        var vertices2 = [
            SatinVertex(position: .init(0, 0, 0), normal: .init(0, 0, 0), uv: .init(0, 0)),
            SatinVertex(position: .init(1, 0, 0), normal: .init(0, 0, 0), uv: .init(0, 0))
        ]
        XCTAssertEqual(computeBoundsFromVertices(&vertices2, 2), Bounds(min: .init(0, 0, 0), max: .init(1, 0, 0)))

        var vertices3 = [
            SatinVertex(position: .init(0, 0, 0), normal: .init(0, 0, 0), uv: .init(0, 0)),
            SatinVertex(position: .init(1, 0, 0), normal: .init(0, 0, 0), uv: .init(0, 0)),
            SatinVertex(position: .init(0, 1, 0), normal: .init(0, 0, 0), uv: .init(0, 0)),
            SatinVertex(position: .init(0, 0, 1), normal: .init(0, 0, 0), uv: .init(0, 0))
        ]
        XCTAssertEqual(computeBoundsFromVertices(&vertices3, 4), Bounds(min: .init(0, 0, 0), max: .init(1, 1, 1)))
    }

    func testComputeBoundsFromVerticesAndTransform() {
        let xform = translationMatrixf(1, 1, 1)

        var vertices0: [SatinVertex] = []
        XCTAssertEqual(computeBoundsFromVerticesAndTransform(&vertices0, 0, xform), createBounds())

        var vertices1 = [
            SatinVertex(position: .init(0, 0, 0), normal: .init(0, 0, 0), uv: .init(0, 0))
        ]
        XCTAssertEqual(computeBoundsFromVerticesAndTransform(&vertices1, 1, xform), Bounds(min: .init(1, 1, 1), max: .init(1, 1, 1)))

        var vertices2 = [
            SatinVertex(position: .init(0, 0, 0), normal: .init(0, 0, 0), uv: .init(0, 0)),
            SatinVertex(position: .init(1, 0, 0), normal: .init(0, 0, 0), uv: .init(0, 0))
        ]
        XCTAssertEqual(computeBoundsFromVerticesAndTransform(&vertices2, 2, xform), Bounds(min: .init(1, 1, 1), max: .init(2, 1, 1)))

        var vertices3 = [
            SatinVertex(position: .init(0, 0, 0), normal: .init(0, 0, 0), uv: .init(0, 0)),
            SatinVertex(position: .init(1, 0, 0), normal: .init(0, 0, 0), uv: .init(0, 0)),
            SatinVertex(position: .init(0, 1, 0), normal: .init(0, 0, 0), uv: .init(0, 0)),
            SatinVertex(position: .init(0, 0, 1), normal: .init(0, 0, 0), uv: .init(0, 0))
        ]
        XCTAssertEqual(computeBoundsFromVerticesAndTransform(&vertices3, 4, xform), Bounds(min: .init(1, 1, 1), max: .init(2, 2, 2)))
    }

    func testTransformBounds() {
        let xform0 = translationMatrixf(1, 1, 1)

        XCTAssertEqual(transformBounds(Bounds(min: .init(1, 1, 1), max: .init(2, 2, 2)), xform0), Bounds(min: .init(2, 2, 2), max: .init(3, 3, 3)))

        let xform1 = translationMatrixf(1, 0, 0)

        XCTAssertEqual(transformBounds(Bounds(min: .init(1, 1, 1), max: .init(2, 2, 2)), xform1), Bounds(min: .init(2, 1, 1), max: .init(3, 2, 2)))

        let xform2 = scaleMatrixf(2, 2, 2)

        XCTAssertEqual(transformBounds(Bounds(min: .init(1, 1, 1), max: .init(2, 2, 2)), xform2), Bounds(min: .init(2, 2, 2), max: .init(4, 4, 4)))
    }
}
