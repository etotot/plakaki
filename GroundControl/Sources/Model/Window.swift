//
//  Window.swift
//  GroundControl
//
//  Created by Andrey Marshak on 23/04/2026.
//

import Foundation

public struct _Window: Sendable, Identifiable, Hashable {
    public let id: CGSWindowID

    public let pid: pid_t?
    public let bundleID: String?

    public let title: String?

    public let isMinimized: Bool
    public let isTileable: Bool
}
