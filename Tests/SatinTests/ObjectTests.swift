//
//  ObjectTests.swift
//
//
//  Created by Taylor Holliday on 3/23/22.
//

import Satin
#if SWIFT_PACKAGE
import SatinCore
#endif

import simd
import XCTest

final class ObjectTests: XCTestCase {
    func testObjectConcurrency() throws {
        let object = Object()
//        let lock = NSLock()
//        let mutex = PThreadMutex(type: .normal)
//        let queue = DispatchQueue(label: "ObjectQueue", attributes: .concurrent)

        let unfair = UnfairLock()
        let iterationCount = 100000

        // 0.270 s w/ NSRecursiveLock
        // 0.252 w/ NSLock
        // 0.241 w/ DispatchQueue
        // 0.246 w/ PThreadMutex
        // 0.244 w/ Unfair
        measure {
            DispatchQueue.concurrentPerform(iterations: iterationCount) { _ in
                let newObject = Object()

//                Task {
//                    lock.lock()
//                    object.add(newObject)
//                    lock.unlock()
//                }
//
//                Task {
//                    lock.lock()
//                    object.remove(newObject)
//                    lock.unlock()
//                }
//
//                Task {
//                    lock.lock()
//                    object.removeAll()
//                    lock.unlock()
//                }

//                Task {
//                    queue.sync(flags: .barrier) {
//                        object.add(newObject)
//                    }
//                }
//
//                Task {
//                    queue.sync(flags: .barrier) {
//                        object.remove(newObject)
//                    }
//                }
//
//                Task {
//                    queue.sync(flags: .barrier) {
//                        object.removeAll()
//                    }
//                }

//                Task {
//                    mutex.sync {
//                        object.add(newObject)
//                    }
//                }
//
//                Task {
//                    mutex.sync {
//                        object.remove(newObject)
//                    }
//                }
//
//                Task {
//                    mutex.sync {
//                        object.removeAll()
//                    }
//                }

                Task {
                    unfair.sync {
                        object.add(newObject)
                    }
                }

                Task {
                    unfair.sync {
                        object.remove(newObject)
                    }
                }

                Task {
                    unfair.sync {
                        object.removeAll()
                    }
                }
            }
        }
    }

    func testObjectLocalTransforms() throws {
        let object = Object()

        XCTAssertTrue(simd_equal(object.localMatrix, matrix_identity_float4x4))

        // Ensure matrix updates after changing position.
        object.position = .init(1, 2, 3)
        XCTAssertTrue(simd_equal(object.localMatrix, translationMatrix3f(object.position)))
        object.position = .zero

        object.scale = .init(1, 2, 3)
        XCTAssertTrue(simd_equal(object.localMatrix, scaleMatrix3f(object.scale)))
        object.scale = .init(1, 1, 1)
    }

    func testObjectWorldTransforms() throws {
        let object = Object()
        let child = Object()
        object.add(child)
        object.position = .init(1, 2, 3)

        XCTAssert(simd_equal(child.localMatrix, matrix_identity_float4x4))
        XCTAssert(simd_equal(child.worldMatrix, translationMatrix3f(object.position)))
    }

    func testAddRemoveChild() {
        let object = Object()
        let child = Object()

        XCTAssertEqual(object.children.count, 0)
        object.add(child)
        XCTAssertEqual(object.children.count, 1)
        object.remove(child)
        XCTAssertEqual(object.children.count, 0)
    }

    func testLocalBounds() {
        let mesh = Mesh(
            geometry: SphereGeometry(),
            material: nil
        )
        XCTAssert(
            mesh.localBounds.equals(
                Bounds(
                    min: .init(-1, -1, -1),
                    max: .init(1, 1, 1)
                )
            )
        )
    }
}
