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

    mutating func appendTiledWindow(_ windowId: WindowId, spaceId: Space.ID) {
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

    mutating func removeWindow(_ windowId: WindowId) {
        // TODO: This naive full graph scan is fine for now, but we should
        // likely maintain a windowId -> location index once move/remove gets hot.
        for displayIndex in displays.indices {
            for spaceIndex in displays[displayIndex].spaces.indices {
                displays[displayIndex].spaces[spaceIndex].removeWindow(windowId)
            }
        }
    }

    mutating func moveWindow(
        _ windowId: WindowId,
        fromSpaceId: Space.ID?,
        toSpaceId: Space.ID
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
        _ windowId: WindowId
    ) {
        for displayIndex in displays.indices {
            for spaceIndex in displays[displayIndex].spaces.indices {
                let contains =
                    displays[displayIndex].spaces[spaceIndex].windowIds.contains(windowId)

                if contains {
                    displays[displayIndex].spaces[spaceIndex].focusedWindow = windowId
                }
            }
        }
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

    var focusedSpace: Space? {
        spaces.first { $0.id == focusedSpaceId }
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

    mutating func appendTiledWindow(_ windowId: WindowId) {
        guard tiledRoot?.contains(windowId: windowId) != true else {
            return
        }

        let leaf = Container.leaf(windowId: windowId)

        switch tiledRoot {
        case nil:
            tiledRoot = .stack(direction: .horizontal, children: [leaf])
        case let .stack(direction, children):
            tiledRoot = .stack(direction: direction, children: children + [leaf])
        case let .leaf(existingWindowId):
            tiledRoot = .stack(
                direction: .horizontal,
                children: [
                    .leaf(windowId: existingWindowId),
                    leaf
                ]
            )
        }
    }

    mutating func removeWindow(_ windowId: WindowId) {
        tiledRoot = tiledRoot?.removing(windowId: windowId)
        floatingWindowIds.removeAll { $0 == windowId }

        if focusedWindow == windowId {
            focusedWindow = nil
        }
    }
}

extension Space {
    var windowIds: [WindowId] {
        (tiledRoot?.windowIds() ?? []) + floatingWindowIds
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

private extension Container {
    func windowIds() -> [WindowId] {
        switch self {
        case let .leaf(windowId):
            [windowId]
        case let .stack(_, containers):
            containers.reduce(into: [WindowId]()) { result, element in
                result.append(contentsOf: element.windowIds())
            }
        }
    }

    func contains(windowId: WindowId) -> Bool {
        switch self {
        case let .leaf(leafWindowId):
            leafWindowId == windowId
        case let .stack(_, children):
            children.contains { $0.contains(windowId: windowId) }
        }
    }

    func removing(windowId: WindowId) -> Container? {
        switch self {
        case let .leaf(leafWindowId):
            return leafWindowId == windowId ? nil : self

        case let .stack(direction, children):
            let remainingChildren = children.compactMap {
                $0.removing(windowId: windowId)
            }

            guard !remainingChildren.isEmpty else {
                return nil
            }

            return .stack(direction: direction, children: remainingChildren)
        }
    }
}
