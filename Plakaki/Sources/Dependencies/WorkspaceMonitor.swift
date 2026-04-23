//
//  WorkspaceMonitor.swift
//  Plakaki
//
//  Created by Andrey Marshak on 23/04/2026.
//

@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import Dependencies
import Foundation
import GroundControl

struct WorkspaceMonitor {
    var workspaces: @Sendable () async -> AsyncStream<Workspace>

    var readWorkspace: @Sendable () async -> Workspace
    var readWindows: @Sendable (Space.ID) async -> [Window]

    var setFrame: @Sendable (CGRect, Window.ID) async -> Void
}

private enum WorkspaceMonitorKey: DependencyKey {
    static let liveValue: Plakaki.WorkspaceMonitor = {
        let monitor = GroundControl.WorkspaceMonitor()

        return WorkspaceMonitor {
            await monitor.workspaces()
        } readWorkspace: {
            // swiftlint:disable:next force_try
            try! await monitor.workspace()
        } readWindows: { spaceID in
            let workspace = try? await monitor.workspace()
            return workspace?.displays
                .flatMap(\.spaces)
                .first { $0.id == spaceID }?
                .windows ?? []
        } setFrame: { frame, windowID in
            try? await monitor.setFrame(frame, forWindowID: windowID)
        }
    }()
}

extension DependencyValues {
    var workspaceMonitor: Plakaki.WorkspaceMonitor {
        get { self[WorkspaceMonitorKey.self] }
        set { self[WorkspaceMonitorKey.self] = newValue }
    }
}
