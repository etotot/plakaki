//
//  LayoutPlan.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 22/04/2026.
//

import Foundation

public struct LayoutPlan: Sendable, Equatable {
    public var windows: [WindowId: WindowLayout]
}

extension LayoutPlan {
    static var empty: Self {
        Self(windows: [:])
    }
}
