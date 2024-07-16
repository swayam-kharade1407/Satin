//
//  FileWatcher.swift
//  Satin
//
//  Created by Reza Ali on 8/27/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public protocol FileWatcherDelegate: AnyObject {
    func updated(watcher: FileWatcher, filePath: String)
}

public final class FileWatcher {
    public var timeInterval: TimeInterval = 1.0 {
        didSet {
            if timer != nil {
                watch()
            }
        }
    }

    public var filePath: String
    public var timer: Timer?
    var lastModifiedDate: Date?
    public var onUpdate: (() -> Void)?
    public weak var delegate: FileWatcherDelegate?

    public init(filePath: String, timeInterval: TimeInterval = 1.0, active: Bool = true, onUpdate: (() -> Void)? = nil) {
        self.filePath = filePath
        self.timeInterval = timeInterval
        self.onUpdate = onUpdate
        if FileManager.default.fileExists(atPath: self.filePath) {
            do {
                let result = try FileManager.default.attributesOfItem(atPath: self.filePath)
                lastModifiedDate = result[.modificationDate] as? Date
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
                        lastModifiedDate = current
                        onUpdate?()
                        delegate?.updated(watcher: self, filePath: filePath)
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

        if timer != nil {
            unwatch()
        }

        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { [weak self] _ in
            self?.checkFile()
        })
    }

    public func unwatch() {
        if let timer = timer {
            timer.invalidate()
        }
        timer = nil
    }

    deinit {
        unwatch()
        delegate = nil
        onUpdate = nil
    }
}
