//
//  LayoutContainer.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 24/04/2026.
//

import GroundControl

public indirect enum Container: Sendable, Equatable {
    public enum LayoutDirection: Sendable, Equatable {
        case vertical
        case horizontal
    }

    case leaf(windowId: Window.ID)
    case stack(direction: LayoutDirection, children: [Container])
}

extension Container {
    // MARK: - Layout Operations

    func inserting(child: Container) -> Container {
        switch self {
        case .leaf:
            .stack(direction: .horizontal, children: [
                self,
                child
            ])
        case let .stack(direction: direction, children: children):
            .stack(direction: direction, children: children + [child])
        }
    }

    func moving(windowID: Window.ID, toIndex: Int) -> Container {
        guard let windowIndex = windowIDs().firstIndex(of: windowID) else {
            return self
        }

        switch self {
        case let .leaf(windowId):
            return self
        case let .stack(direction, children):
            return .stack(
                direction: direction,
                children: children.move(
                    fromOffsets: .init(integer: windowIndex),
                    toOffset: toIndex
                )
            )
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

    // MARK: - Query Helpers

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
}
