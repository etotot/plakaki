//
//  LayoutRoot.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 24/04/2026.
//

import GroundControl

public struct LayoutRoot: Sendable {
    public var displays: [LayoutDisplay]
    public var focusedDisplayID: LayoutDisplay.ID?

    public init(
        displays: [LayoutDisplay] = [],
        focusedDisplayID: LayoutDisplay.ID? = nil
    ) {
        self.displays = displays
        self.focusedDisplayID = focusedDisplayID
    }

    mutating func append(display: LayoutDisplay) {
        if let index = displays.firstIndex(where: { $0.id == display.id }) {
            displays[index] = display
            return
        }

        displays.append(display)
    }

    mutating func remove(displayId: LayoutDisplay.ID) {
        guard let index = displays.firstIndex(where: { $0.id == displayId }) else {
            return
        }

        displays.remove(at: index)
    }

    mutating func setFocusedSpaceID(
        _ spaceId: LayoutSpace.ID,
        displayId: LayoutDisplay.ID
    ) {
        guard let index = displays.firstIndex(where: { $0.id == displayId }) else {
            return
        }

        displays[index].focusedSpaceID = spaceId
    }

    mutating func append(space: LayoutSpace, displayId: LayoutDisplay.ID) {
        guard let index = displays.firstIndex(where: { $0.id == displayId }) else {
            return
        }

        displays[index].append(space: space)
    }

    mutating func remove(spaceId: LayoutSpace.ID, displayId: LayoutDisplay.ID) {
        guard let index = displays.firstIndex(where: { $0.id == displayId }) else {
            return
        }

        displays[index].remove(spaceId: spaceId)
    }

    mutating func appendTiledWindow(_ windowId: Window.ID, spaceId: LayoutSpace.ID) {
        for displayIndex in displays.indices {
            guard let spaceIndex = displays[displayIndex].spaces.firstIndex(
                where: { $0.id == spaceId }
            ) else {
                continue
            }

            displays[displayIndex].spaces[spaceIndex].appendTiledWindow(windowId)
            return
        }
    }

    mutating func removeWindow(_ windowId: Window.ID) {
        // TODO: This naive full graph scan is fine for now, but we should
        // likely maintain a windowId -> location index once move/remove gets hot.
        for displayIndex in displays.indices {
            for spaceIndex in displays[displayIndex].spaces.indices {
                displays[displayIndex].spaces[spaceIndex].removeWindow(windowId)
            }
        }
    }

    mutating func moveWindow(
        _ windowId: Window.ID,
        fromSpaceId: LayoutSpace.ID?,
        toSpaceId: LayoutSpace.ID
    ) {
        // TODO: This naive full graph scan is fine for now, but we should
        // likely maintain a windowId -> location index once move/remove gets hot.
        for displayIndex in displays.indices {
            for spaceIndex in displays[displayIndex].spaces.indices {
                let shouldRemove = fromSpaceId == nil || displays[displayIndex].spaces[spaceIndex].id == fromSpaceId

                guard shouldRemove else {
                    continue
                }

                displays[displayIndex].spaces[spaceIndex].removeWindow(windowId)
            }
        }

        appendTiledWindow(windowId, spaceId: toSpaceId)
    }

    mutating func focusWindow(
        _ windowId: Window.ID
    ) {
        for displayIndex in displays.indices {
            for spaceIndex in displays[displayIndex].spaces.indices {
                let contains =
                    displays[displayIndex].spaces[spaceIndex].windowIDs.contains(windowId)

                if contains {
                    displays[displayIndex].spaces[spaceIndex].focusedWindow = windowId
                }
            }
        }
    }
}
