//
//  WorkspaceSnapshot.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 21/04/2026.
//

public struct WorkspaceSnapshot: Sendable {
    public var displays: [ObservedDisplay]

    public init(displays: [ObservedDisplay] = []) {
        self.displays = displays
    }
}

public struct ObservedDisplay: Identifiable, Sendable {
    public var id: Display.ID
    public var activeSpaceId: Space.ID
    public var spaces: [ObservedSpace]

    public init(
        id: Display.ID,
        activeSpaceId: Space.ID,
        spaces: [ObservedSpace] = []
    ) {
        self.id = id
        self.activeSpaceId = activeSpaceId
        self.spaces = spaces
    }
}

public struct ObservedSpace: Identifiable, Sendable {
    public var id: Space.ID
    public var windows: [ObservedWindow]

    public init(
        id: Space.ID,
        windows: [ObservedWindow] = []
    ) {
        self.id = id
        self.windows = windows
    }
}

public struct ObservedWindow: Identifiable, Sendable {
    public var id: WindowId
    public var state: ObservedWindowState

    public init(
        id: WindowId,
        state: ObservedWindowState = ObservedWindowState()
    ) {
        self.id = id
        self.state = state
    }
}

public struct ObservedWindowState: Sendable {
    public var title: String?
    public var isMinimized: Bool
    public var isTileable: Bool

    public init(
        title: String? = nil,
        isMinimized: Bool = false,
        isTileable: Bool = true
    ) {
        self.title = title
        self.isMinimized = isMinimized
        self.isTileable = isTileable
    }
}
