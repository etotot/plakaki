//
//  WorkspaceMonitorEvent.swift
//  Plakaki
//
//  Created by Andrey Marshak on 23/04/2026.
//

import Foundation

enum WorkspaceMonitorEvent {
    case space(SpaceEvent)
    ///    case application(ApplicationEvent)
    case accessibility(AXEvent)
}
