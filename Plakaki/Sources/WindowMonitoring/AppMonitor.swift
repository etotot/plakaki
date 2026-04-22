//
//  AppMonitor.swift
//  Plakaki
//
//  Created by Andrey Marshak on 20/04/2026.
//

import AppKit
import ApplicationServices
import Dependencies
import Foundation

final class AppMonitor {
    let app: NSRunningApplication
    let appElement: AXUIElement
    let observer: AXObserver

    @Dependency(\.axObserverThreadPool) var threadPool

    init?(app: NSRunningApplication) {
        self.app = app
        appElement = AXUIElementCreateApplication(app.processIdentifier)

        var observer: AXObserver?
        let result = AXObserverCreate(
            app.processIdentifier,
            { _, _, notification, _ in
                let name = notification as String
            },
            &observer
        )

        guard result == .success, let observer else {
            return nil
        }

        self.observer = observer

        let thread = threadPool.thread(for: app.processIdentifier)
        thread.addSource(AXObserverGetRunLoopSource(observer))
    }

    func windowElements() -> [AXUIElement] {
        appElement.discoverWindows()
    }

    func subscribeToAppNotifications() {
        AXObserverAddNotification(
            observer,
            appElement,
            kAXWindowCreatedNotification as CFString,
            nil
        )

        AXObserverAddNotification(
            observer,
            appElement,
            kAXFocusedWindowChangedNotification as CFString,
            nil
        )

        AXObserverAddNotification(
            observer,
            appElement,
            kAXMainWindowChangedNotification as CFString,
            nil
        )
    }

    func subscribeToWindow(_ window: AXUIElement) {
        AXObserverAddNotification(
            observer,
            window,
            kAXUIElementDestroyedNotification as CFString,
            nil
        )

        AXObserverAddNotification(
            observer,
            window,
            kAXWindowMovedNotification as CFString,
            nil
        )

        AXObserverAddNotification(
            observer,
            window,
            kAXWindowResizedNotification as CFString,
            nil
        )
    }
}
