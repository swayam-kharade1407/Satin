//
//  ElementBuffer.swift
//  
//
//  Created by Reza Ali on 7/17/23.
//

import Foundation
import Metal

public protocol ElementBufferDelegate: AnyObject {
    func updated(buffer: ElementBuffer)
}

public class ElementBuffer: Equatable {
    public let id: String = UUID().uuidString

    public private(set) var type: MTLIndexType
    public private(set) var data: UnsafeRawPointer
    public var size: Int {
        type == .uint32 ? MemoryLayout<UInt32>.stride : MemoryLayout<UInt16>.stride
    }

    public private(set) var count: Int // represents the total number of indices
    public var length: Int { size * count }

    public var needsUpdate: Bool = true

    public weak var delegate: ElementBufferDelegate?

    public init(type: MTLIndexType, data: UnsafeRawPointer, count: Int) {
        self.type = type
        self.data = data
        self.count = count
    }

    public func updateData(data: UnsafeRawPointer, count: Int) {
        self.data = data
        self.count = count
        self.needsUpdate = true
        delegate?.updated(buffer: self)
    }

    public static func == (lhs: ElementBuffer, rhs: ElementBuffer) -> Bool {
        lhs === rhs
    }
}
