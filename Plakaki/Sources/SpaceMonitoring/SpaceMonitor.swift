//
//  SpaceMonitor.swift
//  Plakaki
//
//  Created by Andrey Marshak on 22/04/2026.
//

@preconcurrency import AppKit
import Dependencies
import Foundation

struct SpaceMonitor {
    var activeSpace: @Sendable () -> AsyncStream<Void>
}

private enum SpaceMonitorKey: DependencyKey {
    static let liveValue = SpaceMonitor(activeSpace: {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: nil
        ) { _ in
            continuation.yield()
        }
        continuation.onTermination = { _ in
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        return stream
    })
}

extension DependencyValues {
    var spaceMonitor: SpaceMonitor {
        get { self[SpaceMonitorKey.self] }
        set { self[SpaceMonitorKey.self] = newValue }
    }
}
