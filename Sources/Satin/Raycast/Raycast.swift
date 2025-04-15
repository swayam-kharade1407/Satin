//
//  Raycaster.swift
//  Satin
//
//  Created by Reza Ali on 11/29/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import simd

#if SWIFT_PACKAGE
import SatinCore
#endif

public func raycast(ray: Ray, objects: [Object], options: RaycastOptions = .recursiveAndVisible) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    for object in objects {
        if object.intersect(
            ray: ray,
            intersections: &intersections,
            options: options
        ), options.first {
            return intersections
        }
    }
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

public func raycast(origin: simd_float3, direction: simd_float3, objects: [Object], options: RaycastOptions = .recursiveAndVisible) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    for object in objects {
        if object.intersect(
            ray: Ray(origin: origin, direction: direction),
            intersections: &intersections,
            options: options
        ), options.first {
            return intersections
        }
    }
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

public func raycast(camera: Camera, coordinate: simd_float2, objects: [Object], options: RaycastOptions = .recursiveAndVisible) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    for object in objects {
        if object.intersect(
            ray: Ray(camera: camera, coordinate: coordinate),
            intersections: &intersections,
            options: options
        ), options.first {
            return intersections
        }
    }
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

public func raycast(ray: Ray, object: Object, options: RaycastOptions = .recursiveAndVisible) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    if object.intersect(
        ray: ray,
        intersections: &intersections,
        options: options
    ), options.first {
        return intersections
    }
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

public func raycast(origin: simd_float3, direction: simd_float3, object: Object, options: RaycastOptions = .recursiveAndVisible) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    if object.intersect(
        ray: Ray(origin: origin, direction: direction),
        intersections: &intersections,
        options: options
    ), options.first {
        return intersections
    }
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

public func raycast(camera: Camera, coordinate: simd_float2, object: Object, options: RaycastOptions = .recursiveAndVisible) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    if object.intersect(
        ray: Ray(camera: camera, coordinate: coordinate),
        intersections: &intersections,
        options: options
    ), options.first {
        return intersections
    }
    intersections.sort { $0.distance < $1.distance }
    return intersections
}
