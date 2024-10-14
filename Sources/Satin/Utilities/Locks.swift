//
//  Locks.swift
//  Satin
//
//  Created by Reza Ali on 10/13/24.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation

// https://github.com/mattgallagher/CwlUtils/blob/master/Sources/CwlUtils/CwlMutex.swift

/// A basic mutex protocol that requires nothing more than "performing work inside the mutex".
public protocol ScopedMutex {
    /// Perform work inside the mutex
    func sync<R>(execute work: () throws -> R) rethrows -> R

    /// Perform work inside the mutex, returning immediately if the mutex is in-use
    func trySync<R>(execute work: () throws -> R) rethrows -> R?
}

/// A more specific kind of mutex that assume an underlying primitive and unbalanced lock/trylock/unlock operators
public protocol RawMutex: ScopedMutex {
    associatedtype MutexPrimitive

    var underlyingMutex: MutexPrimitive { get set }

    func unbalancedLock()
    func unbalancedTryLock() -> Bool
    func unbalancedUnlock()
}

extension RawMutex {
    public func sync<R>(execute work: () throws -> R) rethrows -> R {
        unbalancedLock()
        defer { unbalancedUnlock() }
        return try work()
    }
    public func trySync<R>(execute work: () throws -> R) rethrows -> R? {
        guard unbalancedTryLock() else { return nil }
        defer { unbalancedUnlock() }
        return try work()
    }
}

/// A basic wrapper around the "NORMAL" and "RECURSIVE" `pthread_mutex_t` (a general purpose mutex). This type is a "class" type to take advantage of the "deinit" method and prevent accidental copying of the `pthread_mutex_t`.
public final class PThreadMutex: RawMutex {
    public typealias MutexPrimitive = pthread_mutex_t

    // Non-recursive "PTHREAD_MUTEX_NORMAL" and recursive "PTHREAD_MUTEX_RECURSIVE" mutex types.
    public enum PThreadMutexType {
        case normal
        case recursive
    }

    public var underlyingMutex = pthread_mutex_t()

    /// Default constructs as ".Normal" or ".Recursive" on request.
    public init(type: PThreadMutexType = .normal) {
        var attr = pthread_mutexattr_t()
        guard pthread_mutexattr_init(&attr) == 0 else {
            preconditionFailure()
        }
        switch type {
            case .normal:
                pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL)
            case .recursive:
                pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        }
        guard pthread_mutex_init(&underlyingMutex, &attr) == 0 else {
            preconditionFailure()
        }
        pthread_mutexattr_destroy(&attr)
    }

    deinit {
        pthread_mutex_destroy(&underlyingMutex)
    }

    public func unbalancedLock() {
        pthread_mutex_lock(&underlyingMutex)
    }

    public func unbalancedTryLock() -> Bool {
        return pthread_mutex_trylock(&underlyingMutex) == 0
    }

    public func unbalancedUnlock() {
        pthread_mutex_unlock(&underlyingMutex)
    }
}

/// A basic wrapper around `os_unfair_lock` (a non-FIFO, high performance lock that offers safety against priority inversion). This type is a "class" type to prevent accidental copying of the `os_unfair_lock`.
@available(OSX 10.12, iOS 10, tvOS 10, watchOS 3, *)
public final class UnfairLock: RawMutex {
    public typealias MutexPrimitive = os_unfair_lock

    public init() {
    }

    /// Exposed as an "unsafe" public property so non-scoped patterns can be implemented, if required.
    public var underlyingMutex = os_unfair_lock()

    public func unbalancedLock() {
        os_unfair_lock_lock(&underlyingMutex)
    }

    public func unbalancedTryLock() -> Bool {
        return os_unfair_lock_trylock(&underlyingMutex)
    }

    public func unbalancedUnlock() {
        os_unfair_lock_unlock(&underlyingMutex)
    }
}

final class RecursiveLock {
    private let recursiveLock: NSRecursiveLock

    public init() {
        recursiveLock = NSRecursiveLock()
    }

    func locked<ReturnValue>(_ f: () throws -> ReturnValue) rethrows -> ReturnValue {
        recursiveLock.lock()
        defer { recursiveLock.unlock() }
        return try f()
    }
}
