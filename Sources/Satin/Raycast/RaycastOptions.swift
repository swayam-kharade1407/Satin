//
//  RaycastOptions.swift
//  Satin
//
//  Created by Reza Ali on 1/3/25.
//

import Foundation
import simd

public struct RaycastOptions {
    public let recursive: Bool
    public let invisible: Bool
    public let first: Bool

    public static let recursiveAndVisible = RaycastOptions(
        recursive: true,
        invisible: false,
        first: false
    )

    public static let recursiveAndInvisible = RaycastOptions(
        recursive: true,
        invisible: true,
        first: false
    )

    public static let recursiveVisibleAndFirst = RaycastOptions(
        recursive: true,
        invisible: false,
        first: true
    )

    public static let recursiveInvisibleAndFirst = RaycastOptions(
        recursive: true,
        invisible: true,
        first: true
    )

    public init(recursive: Bool, invisible: Bool, first: Bool) {
        self.recursive = recursive
        self.invisible = invisible
        self.first = first
    }
}
