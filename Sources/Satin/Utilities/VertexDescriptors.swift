//
//  VertexDescriptor.swift
//  Satin
//
//  Created by Reza Ali on 5/25/20.
//

import Metal
import ModelIO
import SatinCore

public func SatinVertexDescriptor() -> MTLVertexDescriptor {
    // position
    let vertexDescriptor = MTLVertexDescriptor()

    let positionIndex = VertexAttributeIndex.Position.rawValue
    vertexDescriptor.attributes[positionIndex].format = MTLVertexFormat.float4
    vertexDescriptor.attributes[positionIndex].offset = 0
    vertexDescriptor.attributes[positionIndex].bufferIndex = 0

    // normal
    let normalIndex = VertexAttributeIndex.Normal.rawValue
    vertexDescriptor.attributes[normalIndex].format = MTLVertexFormat.float3
    vertexDescriptor.attributes[normalIndex].offset = MemoryLayout<Float>.size * 4
    vertexDescriptor.attributes[normalIndex].bufferIndex = 0

    // uv
    let uvIndex = VertexAttributeIndex.Texcoord.rawValue
    vertexDescriptor.attributes[uvIndex].format = MTLVertexFormat.float2
    vertexDescriptor.attributes[uvIndex].offset = MemoryLayout<Float>.size * 8
    vertexDescriptor.attributes[uvIndex].bufferIndex = 0

    let verticesIndex = VertexBufferIndex.Vertices.rawValue
    vertexDescriptor.layouts[verticesIndex].stride = MemoryLayout<Vertex>.stride
    vertexDescriptor.layouts[verticesIndex].stepRate = 1
    vertexDescriptor.layouts[verticesIndex].stepFunction = .perVertex

    return vertexDescriptor
}

public func SatinModelIOVertexDescriptor() -> MDLVertexDescriptor {
    let descriptor = MDLVertexDescriptor()

    var offset = 0
    descriptor.attributes[VertexAttributeIndex.Position.rawValue] = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float4,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<Float>.size * 4

    descriptor.attributes[VertexAttributeIndex.Normal.rawValue] = MDLVertexAttribute(
        name: MDLVertexAttributeNormal,
        format: .float3,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<Float>.size * 4

    descriptor.attributes[VertexAttributeIndex.Texcoord.rawValue] = MDLVertexAttribute(
        name: MDLVertexAttributeTextureCoordinate,
        format: .float2,
        offset: offset,
        bufferIndex: 0
    )

    descriptor.layouts[VertexBufferIndex.Vertices.rawValue] = MDLVertexBufferLayout(stride: MemoryLayout<Vertex>.stride)

    return descriptor
}
