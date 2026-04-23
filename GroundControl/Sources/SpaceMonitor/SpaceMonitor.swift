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
    case displaysChanged
}

enum SpaceMonitor {
    static func events() -> AsyncStream<SpaceEvent> {
        let (stream, continuation) = AsyncStream<SpaceEvent>.makeStream()

        let activeSpaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: nil
        ) { _ in
            continuation.yield(.activeSpaceChanged)
        }

        let displaysObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: nil
        ) { _ in
            continuation.yield(.displaysChanged)
        }

        continuation.onTermination = { _ in
            NSWorkspace.shared.notificationCenter.removeObserver(activeSpaceObserver)
            NotificationCenter.default.removeObserver(displaysObserver)
        }

        return stream
    }
}
