//
//  WorkspaceMonitorEvent.swift
//  Plakaki
//
//  Created by Andrey Marshak on 23/04/2026.
//

import Foundation

enum WorkspaceMonitorEvent {
    case activeSpaceChanged
    case appWindowCreated(pid_t)
    case appFocusedWindowChanged(pid_t)
    case windowMoved(CGSWindowID?)
    case windowResized(CGSWindowID?)
    case windowDestroyed(CGSWindowID?)
    case applicationLaunched(pid_t)
    case applicationTerminated(pid_t)
}
