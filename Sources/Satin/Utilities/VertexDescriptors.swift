//
//  VertexDescriptor.swift
//  Satin
//
//  Created by Reza Ali on 5/25/20.
//

import Metal
import ModelIO

#if SWIFT_PACKAGE
import SatinCore
#endif

public func ModelIOVertexDescriptor(_ mtlVertexDescriptor: MTLVertexDescriptor) -> MDLVertexDescriptor {
    let descriptor = MDLVertexDescriptor()

    var bufferIndicies = [Int]()
    for index in VertexAttributeIndex.allCases {
        if let attribute = mtlVertexDescriptor.attributes[index.rawValue] {
            print(attribute)
            descriptor.attributes[index.rawValue] = MDLVertexAttribute(
                name: index.mdlName,
                format: attribute.format.mdlFormat,
                offset: attribute.offset,
                bufferIndex: attribute.bufferIndex
            )
            bufferIndicies.append(attribute.bufferIndex)
        }
    }

    for index in bufferIndicies {
        if let layout = mtlVertexDescriptor.layouts[index] {
            descriptor.layouts[index] = MDLVertexBufferLayout(stride: layout.stride)
        }
    }

    return descriptor
}

public func SatinVertexDescriptor() -> MTLVertexDescriptor {
    // position
    let vertexDescriptor = MTLVertexDescriptor()

    let positionIndex = VertexAttributeIndex.Position.rawValue
    vertexDescriptor.attributes[positionIndex].format = MTLVertexFormat.float3
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
    vertexDescriptor.layouts[verticesIndex].stride = MemoryLayout<SatinVertex>.stride
    vertexDescriptor.layouts[verticesIndex].stepRate = 1
    vertexDescriptor.layouts[verticesIndex].stepFunction = .perVertex

    return vertexDescriptor
}

public func SatinModelIOVertexDescriptor() -> MDLVertexDescriptor {
    let descriptor = MDLVertexDescriptor()

    var offset = 0
    descriptor.attributes[VertexAttributeIndex.Position.rawValue] = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float3,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<simd_float3>.stride

    descriptor.attributes[VertexAttributeIndex.Normal.rawValue] = MDLVertexAttribute(
        name: MDLVertexAttributeNormal,
        format: .float3,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<simd_float3>.stride

    descriptor.attributes[VertexAttributeIndex.Texcoord.rawValue] = MDLVertexAttribute(
        name: MDLVertexAttributeTextureCoordinate,
        format: .float2,
        offset: offset,
        bufferIndex: 0
    )

    descriptor.layouts[VertexBufferIndex.Vertices.rawValue] = MDLVertexBufferLayout(stride: MemoryLayout<SatinVertex>.stride)

    return descriptor
}
