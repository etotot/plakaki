//
//  WorkspaceSnapshotBuilder.swift
//  Plakaki
//
//  Created by Andrey Marshak on 21/04/2026.
//

import FlightDeck
import GroundControl

struct WorkspaceSnapshotBuilder {
    var spaceManager: SpaceManager
    var appEnumerator: AppEnumerator

    func makeSnapshot() -> WorkspaceSnapshot {
        WorkspaceSnapshot(
            displays: spaceManager.readDisplays().compactMap(makeDisplay)
        )
    }

    private func makeDisplay(
        from display: ManagedDisplaySpaces
    ) -> ObservedDisplay? {
        guard let activeSpaceId = display.currentSpaceID ?? display.spaces.first?.managedSpaceID else {
            return nil
        }

        return ObservedDisplay(
            id: display.displayIdentifier,
            activeSpaceId: activeSpaceId,
            spaces: display.spaces.map(makeSpace)
        )
    }

    private func makeSpace(from space: ManagedSpace) -> ObservedSpace {
        ObservedSpace(
            id: space.managedSpaceID,
            windows: spaceManager.readWindows(space).map(makeWindow)
        )
    }

    private func makeWindow(from windowId: CGSWindowID) -> ObservedWindow {
        guard let element = appEnumerator.windowMap[windowId] else {
            return ObservedWindow(id: windowId, isTileable: false)
        }

        return ObservedWindow(
            id: windowId,
            bundleId: element.bundleId(),
            title: element.title(),
            isMinimized: element.isMinimized() ?? false
        )
    }
}
