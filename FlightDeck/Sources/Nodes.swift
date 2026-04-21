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
