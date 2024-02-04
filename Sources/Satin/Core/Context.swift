//
//  Context.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

open class Context {
    public var device: MTLDevice
    public var sampleCount: Int
    public var colorPixelFormat: MTLPixelFormat
    public var depthPixelFormat: MTLPixelFormat
    public var stencilPixelFormat: MTLPixelFormat
    public var vertexAmplificationCount: Int

    public init(device: MTLDevice,
                sampleCount: Int,
                colorPixelFormat: MTLPixelFormat,
                depthPixelFormat: MTLPixelFormat = .invalid,
                stencilPixelFormat: MTLPixelFormat = .invalid,
                vertexAmplificationCount: Int = 1)
    {
        self.device = device
        self.sampleCount = sampleCount
        self.colorPixelFormat = colorPixelFormat
        self.depthPixelFormat = depthPixelFormat
        self.stencilPixelFormat = stencilPixelFormat
        self.vertexAmplificationCount = vertexAmplificationCount
    }
}

extension Context: Equatable {
    public static func == (lhs: Context, rhs: Context) -> Bool {
        lhs === rhs
    }
}
