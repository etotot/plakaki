//
//  Workspace.swift
//  GroundControl
//
//  Created by Andrey Marshak on 23/04/2026.
//

public struct Workspace: Sendable, Hashable {
    public let displays: [Display]
    public let focusedDisplayID: Display.ID?
}
