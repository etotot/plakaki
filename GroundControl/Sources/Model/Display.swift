//
//  Display.swift
//  GroundControl
//
//  Created by Andrey Marshak on 23/04/2026.
//

import Foundation

public struct Display: Sendable, Identifiable, Hashable {
    public let id: String

    public let spaces: [Space]
    public let focusedSpaceID: Space.ID

    public init(
        id: String,
        spaces: [Space],
        focusedSpaceID: Space.ID
    ) {
        self.id = id
        self.spaces = spaces
        self.focusedSpaceID = focusedSpaceID
    }
}
