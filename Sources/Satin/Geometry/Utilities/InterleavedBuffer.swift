//
//  InterleavedBuffer.swift
//
//
//  Created by Reza Ali on 7/13/23.
//

import Foundation
import Metal

public protocol InterleavedBufferAttribute: VertexAttribute {
    var buffer: InterleavedBuffer { get }
    var offset: Int { get }
}

public protocol InterleavedBufferDelegate: AnyObject {
    func updated(buffer: InterleavedBuffer)
}

public class InterleavedBuffer: Equatable {
    public let id: String = UUID().uuidString

    public let index: VertexBufferIndex
    public private(set) var data: UnsafeRawPointer?
    public private(set) var stride: Int // represents the distance to another vertex (in bytes) i.e. MemoryLayout<Float>.size * 4
    public private(set) var count: Int // represents the total number of vertices

    var stepRate: Int
    var stepFunction: MTLVertexStepFunction

    var length: Int { stride * count }

    var source: Any?

    public var needsUpdate: Bool = true

    public weak var delegate: InterleavedBufferDelegate?

    public init(index: VertexBufferIndex, data: UnsafeRawPointer?, stride: Int, count: Int, source: Any, stepRate: Int = 1, stepFunction: MTLVertexStepFunction = .perVertex) {
        self.index = index
        self.data = data
        self.stride = stride
        self.count = count
        self.source = source
        self.stepRate = stepRate
        self.stepFunction = stepFunction
    }

    public func updateData(data: UnsafeRawPointer, stride: Int, count: Int, source: Any) {
        self.stride = stride
        self.count = count
        self.source = source
        self.data = data
        self.needsUpdate = true
        delegate?.updated(buffer: self)
    }

    public static func == (lhs: InterleavedBuffer, rhs: InterleavedBuffer) -> Bool {
        lhs === rhs
    }

    deinit {
        source = nil
    }
}

