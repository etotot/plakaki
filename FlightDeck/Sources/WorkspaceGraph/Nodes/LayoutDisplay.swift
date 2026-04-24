//
//  LayoutDisplay.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 24/04/2026.
//

import Foundation

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
