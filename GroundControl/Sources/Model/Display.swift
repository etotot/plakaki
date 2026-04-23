//
//  Display.swift
//  GroundControl
//
//  Created by Andrey Marshak on 23/04/2026.
//

import Foundation

public struct _Display: Sendable, Identifiable, Hashable {
    public let id: String

    public let spaces: [_Space]
    public let focusedSpaceID: _Space.ID
}
