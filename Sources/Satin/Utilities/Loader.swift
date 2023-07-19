//
//  USDZLoader.swift
//  Satin
//
//  Created by Reza Ali on 4/3/23.
//

import Foundation
import Metal
import MetalKit
import ModelIO
import SatinCore

public func loadAsset(url: URL, textureLoader: MTKTextureLoader? = nil) -> Object? {
    let asset = MDLAsset(url: url)

    if textureLoader != nil { asset.loadTextures() }

    let fileName = url.lastPathComponent.replacingOccurrences(of: url.pathExtension, with: "")
    let container = Object(fileName)

    for i in 0 ..< asset.count {
        let mdlObject = asset.object(at: i)
        var stnObject: Object
        if let mdlMesh = mdlObject as? MDLMesh {
            stnObject = loadMesh(mdlMesh: mdlMesh, textureLoader: textureLoader)
        }
        else {
            stnObject = Object(mdlObject.name)
        }
        container.add(stnObject)

        if let transform = mdlObject.transform {
            stnObject.localMatrix = transform.matrix
        }
        loadAssetChildren(parent: stnObject, children: mdlObject.children.objects, textureLoader: textureLoader)
    }

    return container
}

func loadMesh(mdlMesh: MDLMesh, textureLoader: MTKTextureLoader?) -> Mesh {
    let geometry = Geometry()
    let stnMesh = Mesh(label: mdlMesh.name, geometry: geometry, material: nil)
    stnMesh.cullMode = .none

    mdlMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.0)

    let descriptor = mdlMesh.vertexDescriptor

    var bufferInterleaved: [Int: Bool] = [:]
    var bufferIndexMap: [Int: VertexBufferIndex] = [:]
    var bufferIndexAttributes: [Int: [MDLVertexAttribute]] = [:]

    for i in 0 ..< descriptor.attributes.count {
        if let attribute = descriptor.attributes.object(at: i) as? MDLVertexAttribute, attribute.format != .invalid {
            let bufferIndex = attribute.bufferIndex

            if bufferInterleaved[bufferIndex] != nil {
                bufferInterleaved[bufferIndex] = true
                bufferIndexMap[bufferIndex] = .Vertices
                bufferIndexAttributes[bufferIndex] = bufferIndexAttributes[bufferIndex]! + [attribute]
            }
            else {
                bufferInterleaved[bufferIndex] = false
                bufferIndexMap[bufferIndex] = VertexAttributeIndex(name: attribute.name).bufferIndex
                bufferIndexAttributes[bufferIndex] = [attribute]
            }
        }
    }

    for (bufferIndex, vertexBuffer) in mdlMesh.vertexBuffers.enumerated() {
        let count = mdlMesh.vertexCount
        let stride = vertexBuffer.length / count
        let bytes = vertexBuffer.map().bytes
        let index = bufferIndexMap[bufferIndex]!

        if bufferInterleaved[bufferIndex]! {
            let buffer = InterleavedBuffer(index: index, data: bytes, stride: stride, count: count, source: vertexBuffer)

            for attribute in bufferIndexAttributes[bufferIndex]! {
                let offset = attribute.offset
                let attributeIndex = VertexAttributeIndex(name: attribute.name)
                switch attribute.format {
                    case .float4:
                        geometry.addAttribute(
                            Float4InterleavedBufferAttribute(
                                buffer: buffer,
                                offset: offset
                            ), for: attributeIndex
                        )
                    case .float3:
                        geometry.addAttribute(
                            Float3InterleavedBufferAttribute(
                                buffer: buffer,
                                offset: offset
                            ), for: attributeIndex
                        )
                    case .float2:
                        geometry.addAttribute(
                            Float2InterleavedBufferAttribute(
                                buffer: buffer,
                                offset: offset
                            ), for: attributeIndex
                        )
                    case .float:
                        geometry.addAttribute(
                            FloatInterleavedBufferAttribute(
                                buffer: buffer,
                                offset: offset
                            ), for: attributeIndex
                        )
                    default:
                        fatalError("Format not supported")
                }
            }
        }
        else {
            for attribute in bufferIndexAttributes[bufferIndex]! {
                switch attribute.format {
                    case .float4:
                        let ptr = bytes.bindMemory(to: simd_float4.self, capacity: count)
                        let data = Array(UnsafeBufferPointer(start: ptr, count: count))
                        geometry.addAttribute(
                            Float4BufferAttribute(data: data), for: VertexAttributeIndex(name: attribute.name)
                        )
                    case .float3:
                        if stride == MemoryLayout<MTLPackedFloat3>.stride {
                            let ptr = bytes.bindMemory(to: MTLPackedFloat3.self, capacity: count)
                            let data = Array(UnsafeBufferPointer(start: ptr, count: count))
                            geometry.addAttribute(
                                PackedFloat3BufferAttribute(data: data), for: VertexAttributeIndex(name: attribute.name)
                            )
                        }
                        else if stride == MemoryLayout<simd_float3>.stride {
                            let ptr = bytes.bindMemory(to: simd_float3.self, capacity: count)
                            let data = Array(UnsafeBufferPointer(start: ptr, count: count))
                            geometry.addAttribute(
                                Float3BufferAttribute(data: data), for: VertexAttributeIndex(name: attribute.name)
                            )
                        }
                    case .float2:
                        let ptr = bytes.bindMemory(to: simd_float2.self, capacity: count)
                        let data = Array(UnsafeBufferPointer(start: ptr, count: count))
                        geometry.addAttribute(
                            Float2BufferAttribute(data: data), for: VertexAttributeIndex(name: attribute.name)
                        )
                    case .float:
                        let ptr = bytes.bindMemory(to: Float.self, capacity: count)
                        let data = Array(UnsafeBufferPointer(start: ptr, count: count))
                        geometry.addAttribute(
                            FloatBufferAttribute(data: data), for: VertexAttributeIndex(name: attribute.name)
                        )
                    default:
                        fatalError("Format not supported")
                }
            }
        }
    }

    if let submeshes = mdlMesh.submeshes {
        if submeshes.count > 1 {
            for submeshIndex in 0 ..< submeshes.count {
                if let mdlSubmesh = submeshes.object(at: submeshIndex) as? MDLSubmesh {
                    if mdlSubmesh.geometryType == .triangles {
                        let indexCount = mdlSubmesh.indexCount
                        let indexBuffer = mdlSubmesh.indexBuffer(asIndexType: .uInt32)
                        let indexBytes = indexBuffer.map().bytes.bindMemory(to: UInt32.self, capacity: indexCount)
                        let indexData = Array(UnsafeBufferPointer(start: indexBytes, count: indexCount))

                        var material: Material?
                        if let mdlMaterial = mdlSubmesh.material, let textureLoader = textureLoader {
                            material = PhysicalMaterial(material: mdlMaterial, textureLoader: textureLoader)
                        }

                        stnMesh.addSubmesh(
                            Submesh(
                                label: mdlSubmesh.name,
                                parent: stnMesh,
                                indexData: indexData,
                                material: material
                            )
                        )
                    }
                }
            }
        }
        else {
            if let mdlSubmesh = submeshes.object(at: 0) as? MDLSubmesh {
                if let mdlMaterial = mdlSubmesh.material, let textureLoader = textureLoader {
                    stnMesh.material = PhysicalMaterial(material: mdlMaterial, textureLoader: textureLoader)
                }
                let indexBuffer = mdlSubmesh.indexBuffer(asIndexType: .uInt32)
                geometry.setElements(
                    ElementBuffer(
                        type: .uint32,
                        data: indexBuffer.map().bytes,
                        count: mdlSubmesh.indexCount,
                        source: indexBuffer
                    )
                )
            }
        }
    }

    return stnMesh
}

func loadAssetChildren(parent: Object, children: [MDLObject], textureLoader: MTKTextureLoader?) {
    for child in children {
        var stnObject: Object
        if let mdlMesh = child as? MDLMesh {
            stnObject = loadMesh(mdlMesh: mdlMesh, textureLoader: textureLoader)
        }
        else {
            stnObject = Object(child.name)
        }

        if let transform = child.transform {
            stnObject.localMatrix = transform.matrix
        }
        parent.add(stnObject)
        loadAssetChildren(parent: stnObject, children: child.children.objects, textureLoader: textureLoader)
    }
}
