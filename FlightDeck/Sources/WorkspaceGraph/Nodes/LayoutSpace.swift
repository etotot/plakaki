//
//  LayoutSpace.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 24/04/2026.
//

import GroundControl

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
