import AppKit
@preconcurrency import ApplicationServices
import Foundation
import OSLog

private let logger = Logger(subsystem: "xyz.etotot.GroundControl", category: "AXMonitor")

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
        logger.info(
            "Initialized AXMonitor for application \(app.processIdentifier), bundleID: \(app.bundleIdentifier ?? "<unknown>", privacy: .public)"
        )

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
        logger.debug("Publishing AX event: \(String(describing: event), privacy: .public)")
        continuation?.yield(event)
    }

    private func receive(notification: CFString, element: AXUIElement) {
        logger.debug("Received AX notification: \(notification, privacy: .public)")
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
        let appPID = app.processIdentifier
        logger.info("Starting AX monitoring for application \(appPID)")
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
        let appPID = app.processIdentifier
        logger.info("Stopping AX monitoring for application \(appPID)")
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
        let appPID = app.processIdentifier
        logger.debug("Subscribing to window \(windowID) for application \(appPID)")

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

        let appPID = app.processIdentifier
        logger.debug("Unsubscribing from window \(windowID) for application \(appPID)")

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
