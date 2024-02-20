//
//  ForgeMetalViewRendererDelegate.swift
//  Forging
//
//  Created by Reza Ali on 1/22/24.
//

import Foundation
import QuartzCore

#if canImport(AppKit)
import AppKit
#endif

internal protocol MetalViewRendererDelegate: AnyObject {
    var id: String { get }
    func draw(metalLayer: CAMetalLayer)
    func drawableResized(size: CGSize, scaleFactor: CGFloat)
}
