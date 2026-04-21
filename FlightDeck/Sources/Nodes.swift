//
//  Nodes.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 20/04/2026.
//

import GroundControl

public typealias WindowId = String

public struct Root: Sendable {
    public var displays: [Display]
    public var focusedDisplayId: Display.ID?

    public init(
        displays: [Display] = [],
        focusedDisplayId: Display.ID? = nil
    ) {
        self.displays = displays
        self.focusedDisplayId = focusedDisplayId
    }

    mutating func append(display: Display) {
        if let index = displays.firstIndex(where: { $0.id == display.id }) {
            displays[index] = display
            return
        }

        displays.append(display)
    }

    mutating func remove(displayId: Display.ID) {
        guard let index = displays.firstIndex(where: { $0.id == displayId }) else {
            return
        }

        displays.remove(at: index)
    }

    mutating func setFocusedSpaceId(
        _ spaceId: Space.ID,
        displayId: Display.ID
    ) {
        guard let index = displays.firstIndex(where: { $0.id == displayId }) else {
            return
        }

        displays[index].focusedSpaceId = spaceId
    }

    mutating func append(space: Space, displayId: Display.ID) {
        guard let index = displays.firstIndex(where: { $0.id == displayId }) else {
            return
        }

        displays[index].append(space: space)
    }

    mutating func remove(spaceId: Space.ID, displayId: Display.ID) {
        guard let index = displays.firstIndex(where: { $0.id == displayId }) else {
            return
        }

        displays[index].remove(spaceId: spaceId)
    }
}

public struct Display: Identifiable, Sendable {
    public var id: String
    public var spaces: [Space]
    public var focusedSpaceId: Space.ID

    public init(
        id: String,
        spaces: [Space],
        focusedSpaceId: Space.ID
    ) {
        self.id = id
        self.spaces = spaces
        self.focusedSpaceId = focusedSpaceId
    }

    mutating func append(space: Space) {
        if let index = spaces.firstIndex(where: { $0.id == space.id }) {
            spaces[index] = space
            return
        }

        spaces.append(space)
    }

    mutating func remove(spaceId: Space.ID) {
        guard let index = spaces.firstIndex(where: { $0.id == spaceId }) else {
            return
        }

        spaces.remove(at: index)
    }
}

public struct Space: Identifiable, Sendable {
    public var id: CGSSpaceID
    public var tiledRoot: Container?
    public var floatingWindowIds: [WindowId]
    public var focusedWindow: WindowId?

    public init(
        id: CGSSpaceID,
        tiledRoot: Container? = nil,
        floatingWindowIds: [WindowId] = [],
        focusedWindow: WindowId? = nil
    ) {
        self.id = id
        self.tiledRoot = tiledRoot
        self.floatingWindowIds = floatingWindowIds
        self.focusedWindow = focusedWindow
    }
}

public indirect enum Container: Sendable, Equatable {
    public enum LayoutDirection: Sendable, Equatable {
        case vertical
        case horizontal
    }

    case stack(direction: LayoutDirection, children: [Container])
    case leaf(windowId: WindowId)
}
