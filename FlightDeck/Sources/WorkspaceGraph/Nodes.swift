//
//  Nodes.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 20/04/2026.
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

public struct LayoutDisplay: Identifiable, Sendable {
    public var id: String
    public var spaces: [LayoutSpace]
    public var focusedSpaceID: LayoutSpace.ID

    public init(
        id: String,
        spaces: [LayoutSpace],
        focusedSpaceID: LayoutSpace.ID
    ) {
        self.id = id
        self.spaces = spaces
        self.focusedSpaceID = focusedSpaceID
    }

    var focusedSpace: LayoutSpace? {
        spaces.first { $0.id == focusedSpaceID }
    }

    mutating func append(space: LayoutSpace) {
        if let index = spaces.firstIndex(where: { $0.id == space.id }) {
            spaces[index] = space
            return
        }

        spaces.append(space)
    }

    mutating func remove(spaceId: LayoutSpace.ID) {
        guard let index = spaces.firstIndex(where: { $0.id == spaceId }) else {
            return
        }

        spaces.remove(at: index)
    }
}

public struct LayoutSpace: Identifiable, Sendable {
    public var id: CGSSpaceID
    public var tiledRoot: Container?
    public var floatingWindowIDs: [Window.ID]
    public var focusedWindow: Window.ID?

    public init(
        id: CGSSpaceID,
        tiledRoot: Container? = nil,
        floatingWindowIDs: [Window.ID] = [],
        focusedWindow: Window.ID? = nil
    ) {
        self.id = id
        self.tiledRoot = tiledRoot
        self.floatingWindowIDs = floatingWindowIDs
        self.focusedWindow = focusedWindow
    }

    mutating func appendTiledWindow(_ windowId: Window.ID) {
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

    mutating func removeWindow(_ windowId: Window.ID) {
        tiledRoot = tiledRoot?.removing(windowId: windowId)
        floatingWindowIDs.removeAll { $0 == windowId }

        if focusedWindow == windowId {
            focusedWindow = nil
        }
    }
}

extension LayoutSpace {
    var windowIDs: [Window.ID] {
        (tiledRoot?.windowIDs() ?? []) + floatingWindowIDs
    }
}

public indirect enum Container: Sendable, Equatable {
    public enum LayoutDirection: Sendable, Equatable {
        case vertical
        case horizontal
    }

    case stack(direction: LayoutDirection, children: [Container])
    case leaf(windowId: Window.ID)
}

private extension Container {
    func windowIDs() -> [Window.ID] {
        switch self {
        case let .leaf(windowId):
            [windowId]
        case let .stack(_, containers):
            containers.reduce(into: [Window.ID]()) { result, element in
                result.append(contentsOf: element.windowIDs())
            }
        }
    }

    func contains(windowId: Window.ID) -> Bool {
        switch self {
        case let .leaf(leafWindowId):
            leafWindowId == windowId
        case let .stack(_, children):
            children.contains { $0.contains(windowId: windowId) }
        }
    }

    func removing(windowId: Window.ID) -> Container? {
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
