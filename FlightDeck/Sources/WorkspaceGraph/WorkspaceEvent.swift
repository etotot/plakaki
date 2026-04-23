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
    case displayDisconnected(GroundControl.Display.ID)
    case activeSpaceChanged(displayId: GroundControl.Display.ID, spaceId: GroundControl.Space.ID)
    case spaceAdded(GroundControl.Space, displayId: GroundControl.Display.ID)
    case spaceRemoved(GroundControl.Space.ID, displayId: GroundControl.Display.ID)
    case windowDiscovered(GroundControl.Window, spaceId: GroundControl.Space.ID)
    case windowUpdated(GroundControl.Window, spaceId: GroundControl.Space.ID)
    case windowRemoved(Window.ID)
    case windowMoved(windowId: Window.ID, fromSpaceId: GroundControl.Space.ID?, toSpaceId: GroundControl.Space.ID)
}

public enum WorkspaceCommand: Sendable {
    case focusWindow(Window.ID)
    case focusSpace(GroundControl.Space.ID, displayId: GroundControl.Display.ID)
    case focusDisplay(GroundControl.Display.ID)
    case toggleFloating(Window.ID)
}
