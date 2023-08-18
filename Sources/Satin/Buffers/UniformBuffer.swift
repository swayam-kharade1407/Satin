//
//  UniformBuffer.swift
//  Satin
//
//  Created by Reza Ali on 11/3/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation
import Combine
import Metal
import simd

func align256(size: Int) -> Int {
    return ((size + 255) / 256) * 256
}

public final class UniformBuffer {
    public private(set) weak var parameters: ParameterGroup?
    public private(set) var buffer: MTLBuffer?
    public private(set) var index: Int = -1
    public private(set) var offset = 0
    public private(set) var alignedSize: Int

    public init(device: MTLDevice, parameters: ParameterGroup, options: MTLResourceOptions = [.cpuCacheModeWriteCombined]) {
        self.parameters = parameters
        self.alignedSize = align256(size: parameters.size)

        let length = alignedSize * Satin.maxBuffersInFlight

        if let buffer = device.makeBuffer(length: length, options: options) {
            buffer.label = parameters.label
            self.buffer = buffer
            update()
        }
    }

    public func update() {
        guard let parameters = parameters, let buffer = buffer else { return }
        index = (index + 1) % maxBuffersInFlight
        offset = alignedSize * index
        (buffer.contents() + offset).copyMemory(from: parameters.data, byteCount: parameters.size)
    }

    public func reset() {
        index = -1
    }
}
