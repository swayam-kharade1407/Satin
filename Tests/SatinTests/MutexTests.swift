//
//  MutexTests.swift
//  Satin
//
//  Created by Reza Ali on 10/13/24.
//

@preconcurrency import Satin
#if SWIFT_PACKAGE
import SatinCore
#endif

import simd
import XCTest

final class MutexTests: XCTestCase {
    let iterationCount = 100000

    // 0.244 sec
    func testDispatchQueue() throws {
        let object = Object()
        let queue = DispatchQueue(label: "ObjectQueue", attributes: .concurrent)

        measure {
            DispatchQueue.concurrentPerform(iterations: iterationCount) { _ in
                let newObject = Object()

                Task {
                    queue.sync(flags: .barrier) {
                        object.add(newObject)
                    }
                }

                Task {
                    queue.sync(flags: .barrier) {
                        object.remove(newObject)
                    }
                }

                Task {
                    queue.sync(flags: .barrier) {
                        object.removeAll()
                    }
                }
            }
        }
    }

    // 0.236 sec
    func testNSLock() throws {
        let object = Object()
        let lock = NSLock()

        measure {
            DispatchQueue.concurrentPerform(iterations: iterationCount) { _ in
                let newObject = Object()

                Task {
                    lock.lock()
                    object.add(newObject)
                    lock.unlock()
                }

                Task {
                    lock.lock()
                    object.remove(newObject)
                    lock.unlock()
                }

                Task {
                    lock.lock()
                    object.removeAll()
                    lock.unlock()
                }
            }
        }
    }

    // 0.251 sec
    func testNSRecursiveLock() throws {
        let object = Object()
        let lock = NSRecursiveLock()

        measure {
            DispatchQueue.concurrentPerform(iterations: iterationCount) { _ in
                let newObject = Object()

                Task {
                    lock.lock()
                    object.add(newObject)
                    lock.unlock()
                }

                Task {
                    lock.lock()
                    object.remove(newObject)
                    lock.unlock()
                }

                Task {
                    lock.lock()
                    object.removeAll()
                    lock.unlock()
                }
            }
        }
    }

    // 0.244 sec
    func testPThreadMutex() throws {
        let object = Object()
        let mutex = PThreadMutex(type: .normal)

        measure {
            DispatchQueue.concurrentPerform(iterations: iterationCount) { _ in
                let newObject = Object()

                Task {
                    mutex.unbalancedLock()
                    object.add(newObject)
                    mutex.unbalancedUnlock()
                }

                Task {
                    mutex.unbalancedLock()
                    object.remove(newObject)
                    mutex.unbalancedUnlock()
                }

                Task {
                    mutex.unbalancedLock()
                    object.removeAll()
                    mutex.unbalancedUnlock()
                }
            }
        }
    }

    // 0.250 sec
    func testUnfairLock() throws {
        let object = Object()
        let unfairLock = UnfairLock()

        measure {
            DispatchQueue.concurrentPerform(iterations: iterationCount) { _ in
                let newObject = Object()

                Task {
                    unfairLock.unbalancedLock()
                    object.add(newObject)
                    unfairLock.unbalancedUnlock()
                }

                Task {
                    unfairLock.unbalancedLock()
                    object.remove(newObject)
                    unfairLock.unbalancedUnlock()
                }

                Task {
                    unfairLock.unbalancedLock()
                    object.removeAll()
                    unfairLock.unbalancedUnlock()
                }
            }
        }
    }
}
