@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import CoreGraphics
import Foundation
import OSLog

private let logger = Logger(subsystem: "xyz.etotot.GroundControl", category: "WorkspaceMonitor")

private struct WindowMetadata {
    let id: CGSWindowID
    let pid: pid_t?
    let title: String?
}

public actor WorkspaceMonitor {
    private var axMonitors: [pid_t: AXMonitor] = [:]
    private var axMonitorTasks: [pid_t: Task<Void, Never>] = [:]

    // TODO: Would it be better to remove applications array and rely on PIDs to get NSRunningApplication?
    private var applications: [pid_t: NSRunningApplication] = [:]

    private var windowElements: [CGSWindowID: AXUIElement] = [:]
    private var windowMetadata: [CGSWindowID: WindowMetadata] = [:]

    private let threadPool: AXObserverThreadPool

    private var currentWorkspace: Workspace? {
        didSet {
            guard let currentWorkspace else {
                return
            }

            for continuation in subscribers.values {
                continuation.yield(currentWorkspace)
            }
        }
    }

    private var subscribers: [UUID: AsyncStream<Workspace>.Continuation] = [:]

    public init() {
        threadPool = SingleAXObserverThreadPool()
        logger.info("WorkspaceMonitor initialized")
    }

    deinit {
        logger.info("WorkspaceMonitor deinitializing")
        monitoringTask?.cancel()

        for continuation in subscribers.values {
            continuation.finish()
        }
    }

    private var monitoringTask: Task<Void, Never>?

    public func startMonitoring() {
        guard monitoringTask == nil else {
            logger.debug("startMonitoring ignored because monitoring is already active")
            return
        }

        logger.info("Starting workspace monitoring")

        startMonitoringRunningApplications()
        currentWorkspace = try? enrich(ManagedSpacesReader.workspace())

        monitoringTask = Task { [weak self] in
            for await spaceEvent in SpaceMonitor.events() {
                await self?.handleSpaceEvent(spaceEvent)
            }
        }
    }

    public func workspace() throws -> Workspace {
        if let currentWorkspace {
            logger.debug("Returning cached workspace snapshot")
            return currentWorkspace
        }

        logger.debug("Building workspace snapshot on demand")
        return try enrich(ManagedSpacesReader.workspace())
    }

    public func workspaces() -> AsyncStream<Workspace> {
        startMonitoring()

        let (stream, continuation) = AsyncStream<Workspace>.makeStream()
        let uuid = UUID()

        subscribers[uuid] = continuation
        logger.debug("Added workspace subscriber \(uuid, privacy: .public). Total subscribers: \(subscribers.count)")
        continuation.onTermination = { [weak self] _ in
            Task { [weak self] in
                await self?.cancelSubscription(uuid)
            }
        }

        if let currentWorkspace {
            continuation.yield(currentWorkspace)
        }

        return stream
    }

    public func setFrame(_ frame: CGRect, forWindowID windowID: CGSWindowID) async throws {
        guard let element = windowElements[windowID] else {
            logger.debug("Ignoring setFrame for unknown window \(windowID)")
            return
        }

        logger.debug("Setting frame for window \(windowID)")
        try await MainActor.run {
            try element.setFrame(frame)
        }
    }

    private func cancelSubscription(_ uuid: UUID) {
        subscribers[uuid] = nil
        logger.debug("Removed workspace subscriber \(uuid, privacy: .public). Total subscribers: \(subscribers.count)")
    }

    // MARK: - Application Monitoring

    private func startMonitoringRunningApplications() {
        let runningApplications = NSWorkspace.shared.runningApplications
        applications = runningApplications.reduce(into: [:]) { result, application in
            result[application.processIdentifier] = application
        }

        windowMetadata = Self.readWindowMetadata()

        let regularApplications = runningApplications.filter {
            $0.activationPolicy == .regular
        }

        let runningPIDs = Set(regularApplications.map(\.processIdentifier))
        let monitoredPIDs = Set(axMonitors.keys)

        logger.info(
            "Reconciling running applications. Regular apps: \(regularApplications.count), monitored apps: \(monitoredPIDs.count)"
        )

        for pid in monitoredPIDs.subtracting(runningPIDs) {
            stopMonitoringApplication(pid: pid)
        }

        for app in regularApplications where !monitoredPIDs.contains(app.processIdentifier) {
            startMonitoringApplication(app)
        }
    }

    private func startMonitoringApplication(_ app: NSRunningApplication) {
        guard axMonitors[app.processIdentifier] == nil else {
            logger.debug("Application \(app.processIdentifier) is already being monitored")
            return
        }

        guard let monitor = AXMonitor(app: app, threadPool: threadPool) else {
            logger.error("Failed to create AXMonitor for application \(app.processIdentifier)")
            return
        }

        logger.info(
            "Starting monitoring for application \(app.processIdentifier), bundleID: \(app.bundleIdentifier ?? "<unknown>", privacy: .public)"
        )
        axMonitors[app.processIdentifier] = monitor
        monitor.startMonitoring()

        for window in monitor.windowElements() {
            do {
                let windowID = try window.windowID()
                windowElements[windowID] = window
            } catch {
                logger.error("Failed to read window ID: \(String(describing: error))")
            }
        }

        axMonitorTasks[app.processIdentifier] = Task { [weak self] in
            for await event in monitor.events {
                await self?.handle(.accessibility(event))
            }
        }
    }

    private func stopMonitoringApplication(pid: pid_t) {
        logger.info("Stopping monitoring for application \(pid)")
        axMonitorTasks[pid]?.cancel()
        axMonitorTasks[pid] = nil

        axMonitors[pid]?.stopMonitoring()
        axMonitors[pid] = nil

        applications[pid] = nil
    }

    // MARK: - Event Management

    private func handle(_ event: WorkspaceMonitorEvent) {
        logger.debug("Received event: \(String(describing: event), privacy: .public)")
    }

    private func handleSpaceEvent(_ event: SpaceEvent) {
        logger.debug("Handling space event: \(String(describing: event), privacy: .public)")
        // swiftlint:disable:next force_try
        currentWorkspace = try! enrich(ManagedSpacesReader.workspace())
    }

    // MARK: - Workspace Helpers

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
