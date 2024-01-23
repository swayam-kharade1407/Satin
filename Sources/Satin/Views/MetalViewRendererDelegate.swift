//
//  ForgeMetalViewRendererDelegate.swift
//  Forging
//
//  Created by Reza Ali on 1/22/24.
//

import Foundation
import QuartzCore

internal protocol MetalViewRendererDelegate: AnyObject {
    var label: String { get }
    func draw(metalLayer: CAMetalLayer)
    func drawableResized(size: CGSize, scaleFactor: CGFloat)
}
