//
//  Window.swift
//  GroundControl
//
//  Created by Andrey Marshak on 23/04/2026.
//

import Foundation

public struct Window: Sendable, Identifiable, Hashable {
    public let id: CGSWindowID

    public let pid: pid_t?
    public let bundleID: String?

    public let title: String?

    public let isMinimized: Bool
    public let isTileable: Bool

    public init(
        id: CGSWindowID,
        pid: pid_t? = nil,
        bundleID: String? = nil,
        title: String? = nil,
        isMinimized: Bool = false,
        isTileable: Bool = true
    ) {
        self.id = id
        self.pid = pid
        self.bundleID = bundleID
        self.title = title
        self.isMinimized = isMinimized
        self.isTileable = isTileable
    }
}
