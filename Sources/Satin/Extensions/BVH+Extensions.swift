//
//  BVH+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 11/27/22.
//

import simd

#if SWIFT_PACKAGE
import SatinCore
#endif

public struct IntersectionResult {
    public let barycentricCoordinates: simd_float3
    public let distance: Float
    public let normal: simd_float3
    public let position: simd_float3
    public let primitiveIndex: UInt32
}

public extension BVHNode {
    var isLeaf: Bool { triCount > 0 }

    func intersects(ray: Ray) -> Bool {
        return rayBoundsIntersect(ray, aabb)
    }
}

public extension BVH {
    func getNode(index: UInt32) -> BVHNode? {
        guard index < nodesUsed else { return nil }
        return nodes.advanced(by: Int(index)).pointee
    }

    func getTriangleID(index: UInt32) -> UInt32 {
        return triIDs.advanced(by: Int(index)).pointee
    }

    func getCentroid(index: UInt32) -> simd_float3 {
        return centroids.advanced(by: Int(index)).pointee
    }

    func getPosition(index: UInt32) -> simd_float3 {
        return positions.advanced(by: Int(index)).pointee
    }

    func getTriangle(index: UInt32) -> TriangleIndices {
        return triangles.advanced(by: Int(index)).pointee
    }

    func intersects(ray: Ray, index: UInt32) -> Bool {
        guard let node = getNode(index: index) else { return false }
        return node.intersects(ray: ray)
    }

    func intersects(ray: Ray) -> Bool {
        return intersects(ray: ray, index: 0)
    }

    func intersectTriangles(ray: Ray, node: BVHNode, intersections: inout [IntersectionResult]) {
        for i in 0 ..< node.triCount {
            let primitiveIndex = getTriangleID(index: node.leftFirst + i)
            let triangle = getTriangle(index: primitiveIndex)

            let a = getPosition(index: triangle.i0)
            let b = getPosition(index: triangle.i1)
            let c = getPosition(index: triangle.i2)

            var time: Float = -1.0

            if rayTriangleIntersectionTime(ray, a, b, c, &time), time > .leastNonzeroMagnitude {
                let intersection = ray.at(time)
                let bc = getBarycentricCoordinates(intersection, a, b, c)

                intersections.append(
                    IntersectionResult(
                        barycentricCoordinates: bc,
                        distance: simd_length(intersection - ray.origin),
                        normal: simd_normalize(simd_cross(b - a, c - a)),
                        position: intersection,
                        primitiveIndex: primitiveIndex
                    )
                )
            }
        }
    }

    func intersect(ray: Ray, intersections: inout [IntersectionResult], index: UInt32 = 0) {
        guard let node = getNode(index: index), node.intersects(ray: ray) else { return }
        if node.isLeaf {
            intersectTriangles(ray: ray, node: node, intersections: &intersections)
        } else {
            intersect(ray: ray, intersections: &intersections, index: node.leftFirst)
            intersect(ray: ray, intersections: &intersections, index: node.leftFirst + 1)
        }
    }
}
