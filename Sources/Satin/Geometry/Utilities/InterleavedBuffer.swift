//
//  InterleavedBuffer.swift
//
//
//  Created by Reza Ali on 7/13/23.
//

import Foundation
import Metal

public class InterleavedBuffer: Codable {
    var index: VertexBufferIndex
    var data: UnsafeRawPointer
    var stride: Int // represents the distance to another vertex (in bytes) i.e. MemoryLayout<Float>.size * 4
    var count: Int // represents the total number of vertices
    var stepRate: Int
    var stepFunction: MTLVertexStepFunction

    var length: Int {
        stride * count
    }

    public init(index: VertexBufferIndex, data: UnsafeRawPointer, stride: Int, count: Int, stepRate: Int = 1, stepFunction: MTLVertexStepFunction = .perVertex) {
        self.index = index
        self.data = data
        self.stride = stride
        self.count = count
        self.stepRate = stepRate
        self.stepFunction = stepFunction
    }

    private enum CodingKeys: String, CodingKey {
        case index
        case data
        case stride
        case count
        case stepRate
        case stepFunction
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(Data(bytes: data, count: length).base64EncodedString(), forKey: .data)
        try container.encode(stride, forKey: .stride)
        try container.encode(count, forKey: .count)
        try container.encode(stepRate, forKey: .stepRate)
        try container.encode(stepFunction, forKey: .stepFunction)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(VertexBufferIndex.self, forKey: .index)
        let d = try container.decode(Data.self, forKey: .data) as NSData
        data = d.bytes
        stride = try container.decode(Int.self, forKey: .stride)
        count = try container.decode(Int.self, forKey: .count)
        stepRate = try container.decode(Int.self, forKey: .stepRate)
        stepFunction = try container.decode(MTLVertexStepFunction.self, forKey: .stepFunction)
    }
}
