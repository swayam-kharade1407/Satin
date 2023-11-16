//
//  VertexAttribute.swift
//  
//
//  Created by Reza Ali on 8/2/23.
//

import Foundation
import Metal

public protocol VertexAttribute: Equatable, AnyObject {
    associatedtype ValueType: Codable
    var id: String { get }

    var type: AttributeType { get }
    var format: MTLVertexFormat { get }
    var count: Int { get } // this represents how many elements we have in a BufferAttribute (5 positions) or how many vertices we have in an InterleavedBufferAttribute

    var size: Int { get }
    var stride: Int { get }
    var alignment: Int { get }
    var components: Int { get }
    
    var stepRate: Int { get }
    var stepFunction: MTLVertexStepFunction { get }
}
