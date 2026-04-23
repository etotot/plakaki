//
//  Space.swift
//  GroundControl
//
//  Created by Andrey Marshak on 23/04/2026.
//

import Foundation

public struct Space: Sendable, Identifiable, Hashable {
    public let id: CGSSpaceID
    public let windowLookupID: UInt64? // Private id needed to query CGSPrivateAPI

    public let windows: [Window]
    public let focusedWindowID: Window.ID?

    public init(
        id: CGSSpaceID,
        windowLookupID: UInt64?,
        windows: [Window],
        focusedWindowID: Window.ID? = nil
    ) {
        self.id = id
        self.windowLookupID = windowLookupID
        self.windows = windows
        self.focusedWindowID = focusedWindowID
    }
}
