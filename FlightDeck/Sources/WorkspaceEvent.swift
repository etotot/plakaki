//
//  WorkspaceEvent.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 21/04/2026.
//

public enum WorkspaceEvent: Sendable {
    case observation(WorkspaceObservation)
    case command(WorkspaceCommand)
}

public enum WorkspaceObservation: Sendable {
    case snapshotChanged(WorkspaceSnapshot)
    case displayConnected(ObservedDisplay)
    case displayDisconnected(Display.ID)
    case activeSpaceChanged(displayId: Display.ID, spaceId: Space.ID)
    case spaceAdded(ObservedSpace, displayId: Display.ID)
    case spaceRemoved(Space.ID, displayId: Display.ID)
    case windowDiscovered(ObservedWindow, spaceId: Space.ID)
    case windowUpdated(ObservedWindow, spaceId: Space.ID)
    case windowRemoved(WindowId)
    case windowMoved(windowId: WindowId, fromSpaceId: Space.ID?, toSpaceId: Space.ID)
}

public enum WorkspaceCommand: Sendable {
    case focusWindow(WindowId)
    case focusSpace(Space.ID, displayId: Display.ID)
    case focusDisplay(Display.ID)
    case toggleFloating(WindowId)
}
