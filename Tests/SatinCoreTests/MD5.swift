//
//  MD5.swift
//
//
//  Created by Taylor Holliday on 3/26/22.
//

import CryptoKit
import Foundation

import Satin
#if SWIFT_PACKAGE
import SatinCore
#endif

extension Bounds: @retroactive Equatable {
    public static func == (lhs: Bounds, rhs: Bounds) -> Bool {
        simd_equal(lhs.min, rhs.min) && simd_equal(lhs.max, rhs.max)
    }
}

func MD5(data: Data) -> String {
    let digest = Insecure.MD5.hash(data: data)

    return digest.map {
        String(format: "%02hhx", $0)
    }.joined()
}

func MD5<T>(ptr: UnsafeMutablePointer<T>, count: Int) -> String {
    MD5(data: Data(bytesNoCopy: UnsafeMutableRawPointer(ptr), count: count * MemoryLayout<T>.stride, deallocator: .none))
}

func MD5<T>(array: [T]) -> String {
    var hash = Insecure.MD5()
    array.withUnsafeBytes { hash.update(bufferPointer: $0) }
    let digest = hash.finalize()
    return digest.map {
        String(format: "%02hhx", $0)
    }.joined()
}
