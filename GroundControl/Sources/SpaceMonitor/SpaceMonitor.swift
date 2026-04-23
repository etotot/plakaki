//
//  SpaceMonitor.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 23/04/2026.
//

import AppKit
import Foundation

public enum SpaceEvent: Sendable {
    case activeSpaceChanged
}

public enum SpaceMonitor {
    public static var spaceEvents: AsyncStream<SpaceEvent> {
        let (stream, continuation) = AsyncStream<SpaceEvent>.makeStream()
        let observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: nil
        ) { _ in
            continuation.yield(.activeSpaceChanged)
        }

        continuation.onTermination = { _ in
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }

        return stream
    }
}
