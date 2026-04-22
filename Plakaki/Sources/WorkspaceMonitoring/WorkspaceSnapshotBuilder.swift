//
//  WorkspaceSnapshotBuilder.swift
//  Plakaki
//
//  Created by Andrey Marshak on 21/04/2026.
//

import AppKit
import FlightDeck
import GroundControl

struct WorkspaceSnapshotBuilder {
    var spaceManager: SpaceManager
    var appEnumerator: AppEnumerator

    func makeSnapshot() async -> WorkspaceSnapshot {
        let windowMap = await appEnumerator.windowMap()
        return WorkspaceSnapshot(
            displays: spaceManager.readDisplays().compactMap { makeDisplay(from: $0, windowMap: windowMap) }
        )
    }

    private func makeDisplay(
        from display: ManagedDisplaySpaces,
        windowMap: [CGWindowID: AXUIElement]
    ) -> ObservedDisplay? {
        guard let activeSpaceId = display.currentSpaceID ?? display.spaces.first?.managedSpaceID else {
            return nil
        }

        return ObservedDisplay(
            id: display.displayIdentifier,
            activeSpaceId: activeSpaceId,
            spaces: display.spaces.map { makeSpace(from: $0, windowMap: windowMap) }
        )
    }

    private func makeSpace(from space: ManagedSpace, windowMap: [CGWindowID: AXUIElement]) -> ObservedSpace {
        ObservedSpace(
            id: space.managedSpaceID,
            windows: spaceManager.readWindows(space).map { makeWindow(from: $0, windowMap: windowMap) }
        )
    }

    private func makeWindow(from windowId: CGSWindowID, windowMap: [CGWindowID: AXUIElement]) -> ObservedWindow {
        guard let element = windowMap[windowId] else {
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
