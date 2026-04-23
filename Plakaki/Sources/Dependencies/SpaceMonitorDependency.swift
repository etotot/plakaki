//
//  SpaceMonitorDependency.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 23/04/2026.
//

import Dependencies
import Foundation
import GroundControl

struct SpaceMonitorDependency {
    var spaceEvents: @Sendable () -> AsyncStream<SpaceEvent>
}

private enum SpaceMonitorDependencyKey: DependencyKey {
    static let liveValue: SpaceMonitorDependency = .init {
        SpaceMonitor.spaceEvents
    }
}

extension DependencyValues {
    var spaceMonitor: SpaceMonitorDependency {
        get { self[SpaceMonitorDependencyKey.self] }
        set { self[SpaceMonitorDependencyKey.self] = newValue }
    }
}

extension AsyncStream where Element == SpaceEvent {
    var activeSpaceChangedEvents: AsyncFilterSequence<Self> {
        filter { SpaceEvent.activeSpaceChanged == $0 }
    }
}
