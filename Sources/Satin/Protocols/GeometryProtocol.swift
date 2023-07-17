//
//  Geometry.swift
//  
//
//  Created by Reza Ali on 7/12/23.
//

import Foundation
import Metal
import Combine
import SatinCore

//public protocol Geometry: Equatable, Codable {
//    var id: String { get }
//
//    var context: Context? { get set }
//
//    var vertexDescriptor: MTLVertexDescriptor { get }
//
//    var primitiveType: MTLPrimitiveType { get }
//    var indexType: MTLIndexType { get }
//    var windingOrder: MTLWinding { get }
//
//    var vertexBuffers: [VertexBufferIndex: MTLBuffer?] { get }
//    var vertexBuffer: MTLBuffer? { get }
//    var indexBuffer: MTLBuffer? { get }
//
//    var indexCount: Int { get }
//    var vertexCount: Int { get }
//
//    var updatePublisher: PassthroughSubject<any Geometry, Never> { get } // publishes when geometry changes
//
//    func setup()
//    func update(_ commandBuffer: MTLCommandBuffer)
//
//    var bounds: Bounds { get }
//    func intersects(ray: Ray) -> Bool
//    func intersect(ray: Ray, intersections: inout [IntersectionResult])
//    func computeBounds() -> Bounds
//}
