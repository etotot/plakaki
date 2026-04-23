//
//  WorkspaceEvent.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 21/04/2026.
//

import GroundControl

public enum WorkspaceEvent: Sendable {
    case observation(WorkspaceObservation)
    case command(WorkspaceCommand)
}

public enum WorkspaceObservation: Sendable {
    case snapshotChanged(GroundControl.Workspace)
    case displayConnected(GroundControl.Display)
    case displayDisconnected(Display.ID)
    case activeSpaceChanged(displayId: Display.ID, spaceId: Space.ID)
    case spaceAdded(GroundControl.Space, displayId: Display.ID)
    case spaceRemoved(Space.ID, displayId: Display.ID)
    case windowDiscovered(GroundControl.Window, spaceId: Space.ID)
    case windowUpdated(GroundControl.Window, spaceId: Space.ID)
    case windowRemoved(Window.ID)
    case windowMoved(windowId: Window.ID, fromSpaceId: Space.ID?, toSpaceId: Space.ID)
}

public enum WorkspaceCommand: Sendable {
    case focusWindow(Window.ID)
    case focusSpace(Space.ID, displayId: Display.ID)
    case focusDisplay(Display.ID)
    case toggleFloating(Window.ID)
}
