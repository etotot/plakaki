//
//  AppEnumerator.swift
//  Plakaki
//
//  Created by Andrey Marshak on 20/04/2026.
//

import AppKit
import Foundation

final class AppEnumerator {
    private var appMonitors: [pid_t: AppMonitor] = .init()

    private(set) var windowMap: [CGWindowID: AXUIElement] = .init()

    func enumerateApps() {
        let workspace = NSWorkspace.shared

        let applications = workspace.runningApplications.filter {
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
                    print(error)
                }
                monitor?.subscribeToWindow(window)
            }
        }
    }
}
