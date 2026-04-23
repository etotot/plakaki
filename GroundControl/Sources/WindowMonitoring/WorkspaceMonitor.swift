@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import CoreGraphics
import Foundation
import OSLog

private let logger = Logger(subsystem: "xyz.etotot.Plakaki", category: "groundControl.windowMonitoring")

public actor WorkspaceMonitor {
    private var appMonitors: [pid_t: AppMonitor] = [:]
    private var windowElements: [CGSWindowID: AXUIElement] = [:]
    private let threadPool: AXObserverThreadPool

    public init() {
        threadPool = SingleAXObserverThreadPool()
    }

    public func enumerateApplications() {
        let applications = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }

        for app in applications {
            let monitor = AppMonitor(app: app, threadPool: threadPool)
            appMonitors[app.processIdentifier] = monitor
            monitor?.subscribeToAppNotifications()

            for window in monitor?.windowElements() ?? [] {
                do {
                    let windowID = try window.windowID()
                    windowElements[windowID] = window
                } catch {
                    logger.error("Failed to read window ID: \(String(describing: error))")
                }

                monitor?.subscribeToWindow(window)
            }
        }
    }

    public func workspace() throws -> Workspace {
        try enrich(ManagedSpacesReader.workspace())
    }

    public func setFrame(_ frame: CGRect, forWindowID windowID: CGSWindowID) throws {
        guard let element = windowElements[windowID] else {
            return
        }

        try element.setFrame(frame)
    }

    private func enrich(_ workspace: Workspace) -> Workspace {
        Workspace(
            displays: workspace.displays.map(enrich),
            focusedDisplayID: workspace.focusedDisplayID
        )
    }

    private func enrich(_ display: Display) -> Display {
        Display(
            id: display.id,
            spaces: display.spaces.map(enrich),
            focusedSpaceID: display.focusedSpaceID
        )
    }

    private func enrich(_ space: Space) -> Space {
        Space(
            id: space.id,
            windowLookupID: space.windowLookupID,
            windows: space.windows.map(enrich),
            focusedWindowID: space.focusedWindowID
        )
    }

    private func enrich(_ window: Window) -> Window {
        guard let element = windowElements[window.id] else {
            return window
        }

        return Window(
            id: window.id,
            pid: element.processIdentifier(),
            bundleID: element.bundleID(),
            title: element.title(),
            isMinimized: element.isMinimized() ?? false,
            isTileable: true
        )
    }
}
