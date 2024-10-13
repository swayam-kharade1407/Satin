//
//  FileWatcher.swift
//  Satin
//
//  Created by Reza Ali on 8/27/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public final class FileWatcher: Sendable {
    public let filePath: String
    public let timeInterval: TimeInterval
    private nonisolated(unsafe) let onUpdate: (() -> Void)?

    private nonisolated(unsafe) var lastModifiedDate: Date?
    private let lastModifiedDateQueue = DispatchQueue(label: "FileWatcherDateQueue", attributes: .concurrent)

    private nonisolated(unsafe) var timer: Timer?
    private let timerQueue = DispatchQueue(label: "FileWatcherTimerQueue", attributes: .concurrent)

    public init(filePath: String, timeInterval: TimeInterval = 1.0, active: Bool = true, onUpdate: (() -> Void)? = nil) {
        self.filePath = filePath
        self.timeInterval = timeInterval
        self.onUpdate = onUpdate
        if FileManager.default.fileExists(atPath: self.filePath) {
            do {
                let result = try FileManager.default.attributesOfItem(atPath: self.filePath)
                lastModifiedDateQueue.sync(flags: .barrier) {
                    lastModifiedDate = result[.modificationDate] as? Date
                }
            } catch {
                print("FileWatcher Error: \(error.localizedDescription)")
            }
            if active {
                watch()
            }
        } else {
            print("File: \(filePath) does not exist")
        }
    }

    @objc func checkFile() {
        if FileManager.default.fileExists(atPath: filePath) {
            do {
                let result = try FileManager.default.attributesOfItem(atPath: filePath)
                let currentModifiedDate = result[.modificationDate] as? Date
                if let current = currentModifiedDate, let last = lastModifiedDate {
                    if current > last {
                        lastModifiedDateQueue.sync(flags: .barrier) {
                            lastModifiedDate = current
                        }
                        onUpdate?()
                    }
                }
            } catch {
                print("FileWatcher Error: \(error)")
            }
        }
    }

    public func watch() {
        guard Thread.current == .main else {
            DispatchQueue.main.async { [weak self] in
                self?.watch()
            }
            return
        }

        timerQueue.sync(flags: .barrier) {
            if self.timer != nil {
                self.unwatch()
            }
            self.timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { [weak self] _ in
                self?.checkFile()
            })
        }
    }

    public func unwatch() {
        timerQueue.sync(flags: .barrier) {
            if let timer {
                timer.invalidate()
            }
            self.timer = nil
        }
    }

    deinit {
        unwatch()
    }
}
