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
}
