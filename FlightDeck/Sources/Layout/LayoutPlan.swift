//
//  LayoutPlan.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 22/04/2026.
//

import Foundation
import GroundControl

public struct LayoutPlan: Sendable, Equatable {
    public var windows: [Window.ID: WindowLayout]
}

extension LayoutPlan {
    static var empty: Self {
        Self(windows: [:])
    }
}
