//
//  Workspace.swift
//  GroundControl
//
//  Created by Andrey Marshak on 23/04/2026.
//

public struct _Workspace: Sendable, Hashable {
    public let displays: [_Display]
    public let focusedDisplayID: _Display.ID?
}
