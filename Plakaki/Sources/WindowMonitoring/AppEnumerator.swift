//
//  AppEnumerator.swift
//  Plakaki
//
//  Created by Andrey Marshak on 20/04/2026.
//

@preconcurrency import AppKit
import Dependencies
import Foundation
import OSLog

private let logger = Logger(subsystem: "xyz.etotot.Plakaki", category: "windowMonitoring")

struct AppEnumerator {
    var enumerateApps: @Sendable () async -> Void
    var windowMap: @Sendable () async -> [CGWindowID: AXUIElement]
}

private actor AppEnumeratorActor {
    private var appMonitors: [pid_t: AppMonitor] = .init()
    private(set) var windowMap: [CGWindowID: AXUIElement] = .init()

    func enumerateApps() {
        let applications = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }

        for app in applications {
            let monitor = AppMonitor(app: app)
            appMonitors[app.processIdentifier] = monitor
            monitor?.subscribeToAppNotifications()
            for window in monitor?.windowElements() ?? [] {
                do {
                    let windowId = try window.windowID()
                    windowMap[windowId] = window
                } catch {
                    logger.error("Failed to read window ID: \(error)")
                }
                monitor?.subscribeToWindow(window)
            }
        }
    }
}

private enum AppEnumeratorKey: DependencyKey {
    static let liveValue: AppEnumerator = {
        let actor = AppEnumeratorActor()
        return AppEnumerator(
            enumerateApps: { await actor.enumerateApps() },
            windowMap: { await actor.windowMap }
        )
    }()

    static let testValue = AppEnumerator(
        enumerateApps: {},
        windowMap: { [:] }
    )
}

extension DependencyValues {
    var appEnumerator: AppEnumerator {
        get { self[AppEnumeratorKey.self] }
        set { self[AppEnumeratorKey.self] = newValue }
    }
}
