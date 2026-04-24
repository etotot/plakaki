import AppKit
@preconcurrency import ApplicationServices
import Foundation

enum AXEvent {
    case windowCreated(appPID: pid_t, windowID: CGSWindowID?)
    case windowDestroyed(appPID: pid_t, windowID: CGSWindowID?)
    case windowMoved(appPID: pid_t, windowID: CGSWindowID?)
    case windowResized(appPID: pid_t, windowID: CGSWindowID?)
    case focusedWindowChanged(appPID: pid_t, windowID: CGSWindowID?)
    case mainWindowChanged(appPID: pid_t, windowID: CGSWindowID?)
}

final class AXMonitor {
    let app: NSRunningApplication
    let appElement: AXUIElement

    private let axObserver: AXObserver
    private let threadPool: AXObserverThreadPool

    private(set) var subscribedWindows: [CGSWindowID: AXUIElement] = .init()

    init?(app: NSRunningApplication, threadPool: AXObserverThreadPool) {
        self.app = app
        self.threadPool = threadPool
        appElement = AXUIElementCreateApplication(app.processIdentifier)

        var observer: AXObserver?
        let callback: AXObserverCallback = { _, element, notification, refcon in
            guard let refcon else { return }

            let monitor = Unmanaged<AXMonitor>
                .fromOpaque(refcon)
                .takeUnretainedValue()

            monitor.receive(notification: notification, element: element)
        }

        let result = AXObserverCreate(
            app.processIdentifier,
            callback,
            &observer
        )

        guard result == .success, let observer else {
            return nil
        }

        axObserver = observer

        let thread = threadPool.thread(for: app.processIdentifier)
        thread.addSource(AXObserverGetRunLoopSource(observer))
    }

    private var continuation: AsyncStream<AXEvent>.Continuation?

    lazy var events: AsyncStream<AXEvent> = AsyncStream(
        bufferingPolicy: .bufferingNewest(50)
    ) { continuation in
        self.continuation = continuation
    }

    private func publish(_ event: AXEvent) {
        continuation?.yield(event)
    }

    private func receive(notification: CFString, element: AXUIElement) {
        // TODO: Should add/remove relevant subscriptions here(ex. window events)
        let windowID = try? element.windowID()

        switch notification as String {
        case kAXWindowCreatedNotification:
            subscribeToWindow(element)
            publish(.windowCreated(appPID: app.processIdentifier, windowID: windowID))
        case kAXUIElementDestroyedNotification:
            // TODO: Test that window id exists
            unsubscribeFromWindow(element)
            publish(.windowDestroyed(appPID: app.processIdentifier, windowID: windowID))
        case kAXWindowMovedNotification:
            publish(.windowMoved(appPID: app.processIdentifier, windowID: windowID))
        case kAXWindowResizedNotification:
            publish(.windowResized(appPID: app.processIdentifier, windowID: windowID))
        case kAXFocusedWindowChangedNotification:
            publish(
                .focusedWindowChanged(
                    appPID: app.processIdentifier,
                    windowID: try? appElement.focusedWindow()?.windowID()
                )
            )
        case kAXMainWindowChangedNotification:
            publish(
                .mainWindowChanged(
                    appPID: app.processIdentifier,
                    windowID: try? appElement.mainWindow()?.windowID()
                )
            )
        default:
            break
        }
    }

    func windowElements() -> [AXUIElement] {
        appElement.discoverWindows()
    }

    func startMonitoring() {
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        AXObserverAddNotification(
            axObserver,
            appElement,
            kAXWindowCreatedNotification as CFString,
            refcon
        )

        AXObserverAddNotification(
            axObserver,
            appElement,
            kAXFocusedWindowChangedNotification as CFString,
            refcon
        )

        AXObserverAddNotification(
            axObserver,
            appElement,
            kAXMainWindowChangedNotification as CFString,
            refcon
        )

        for windowElement in windowElements() {
            subscribeToWindow(windowElement)
        }
    }

    func stopMonitoring() {
        for window in subscribedWindows.values {
            unsubscribeFromWindow(window)
        }

        AXObserverRemoveNotification(
            axObserver,
            appElement,
            kAXWindowCreatedNotification as CFString
        )

        AXObserverRemoveNotification(
            axObserver,
            appElement,
            kAXFocusedWindowChangedNotification as CFString
        )

        AXObserverRemoveNotification(
            axObserver,
            appElement,
            kAXMainWindowChangedNotification as CFString
        )
    }

    private func subscribeToWindow(_ window: AXUIElement) {
        guard let windowID = try? window.windowID(), subscribedWindows[windowID] == nil else {
            return
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        subscribedWindows[windowID] = window

        AXObserverAddNotification(
            axObserver,
            window,
            kAXUIElementDestroyedNotification as CFString,
            refcon
        )

        AXObserverAddNotification(
            axObserver,
            window,
            kAXWindowMovedNotification as CFString,
            refcon
        )

        AXObserverAddNotification(
            axObserver,
            window,
            kAXWindowResizedNotification as CFString,
            refcon
        )
    }

    private func unsubscribeFromWindow(_ window: AXUIElement) {
        guard let windowID = try? window.windowID(), subscribedWindows[windowID] != nil else {
            return
        }

        AXObserverRemoveNotification(
            axObserver,
            window,
            kAXUIElementDestroyedNotification as CFString
        )

        AXObserverRemoveNotification(
            axObserver,
            window,
            kAXWindowMovedNotification as CFString
        )

        AXObserverRemoveNotification(
            axObserver,
            window,
            kAXWindowResizedNotification as CFString
        )

        subscribedWindows[windowID] = nil
    }
}
