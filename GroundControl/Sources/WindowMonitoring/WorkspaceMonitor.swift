@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import CoreGraphics
import Foundation
import OSLog

private let logger = Logger(subsystem: "xyz.etotot.Plakaki", category: "groundControl.windowMonitoring")

private struct WindowMetadata {
    let id: CGSWindowID
    let pid: pid_t?
    let title: String?
}

public actor WorkspaceMonitor {
    private var appMonitors: [pid_t: AppMonitor] = [:]
    private var applications: [pid_t: NSRunningApplication] = [:]
    private var windowElements: [CGSWindowID: AXUIElement] = [:]
    private var windowMetadata: [CGSWindowID: WindowMetadata] = [:]
    private let threadPool: AXObserverThreadPool

    public init() {
        threadPool = SingleAXObserverThreadPool()
    }

    public func enumerateApplications() {
        let runningApplications = NSWorkspace.shared.runningApplications
        applications = runningApplications.reduce(into: [:]) { result, application in
            result[application.processIdentifier] = application
        }
        windowMetadata = Self.readWindowMetadata()

        let regularApplications = runningApplications.filter {
            $0.activationPolicy == .regular
        }

        for app in regularApplications {
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
        enumerateApplications()
        return try enrich(ManagedSpacesReader.workspace())
    }

    public func setFrame(_ frame: CGRect, forWindowID windowID: CGSWindowID) async throws {
        guard let element = windowElements[windowID] else {
            return
        }

        try await MainActor.run {
            try element.setFrame(frame)
        }
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
        let element = windowElements[window.id]
        let metadata = windowMetadata[window.id]
        let pid = element?.processIdentifier() ?? metadata?.pid ?? window.pid
        let application = pid.flatMap { applications[$0] ?? NSRunningApplication(processIdentifier: $0) }

        return Window(
            id: window.id,
            pid: pid,
            bundleID: firstNonEmpty(
                element?.bundleID(),
                application?.bundleIdentifier,
                window.bundleID
            ),
            title: firstNonEmpty(
                element?.title(),
                metadata?.title,
                window.title
            ),
            isMinimized: element?.isMinimized() ?? window.isMinimized,
            isTileable: element != nil
        )
    }

    private static func readWindowMetadata() -> [CGSWindowID: WindowMetadata] {
        guard let windows = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] else {
            return [:]
        }

        return windows.reduce(into: [:]) { result, window in
            guard let windowNumber = window[kCGWindowNumber as String] as? NSNumber else {
                return
            }

            let windowID = windowNumber.uint32Value
            result[windowID] = WindowMetadata(
                id: windowID,
                pid: (window[kCGWindowOwnerPID as String] as? NSNumber).map { pid_t($0.int32Value) },
                title: window[kCGWindowName as String] as? String
            )
        }
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        values.first { value in
            guard let value else {
                return false
            }

            return !value.isEmpty
        } ?? nil
    }
}
