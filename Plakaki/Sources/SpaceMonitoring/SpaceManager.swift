//
//  SpaceManager.swift
//  Plakaki
//
//  Created by Andrey Marshak on 20/04/2026.
//

import Dependencies
import Foundation
import GroundControl
import OSLog

private let logger = Logger(subsystem: "xyz.etotot.Plakaki", category: "spaceMonitoring")

struct SpaceManager {
    var readDisplays: @Sendable () -> [ManagedDisplaySpaces]
    var readWindows: @Sendable (_ space: ManagedSpace) -> [CGSWindowID]
}

private enum SpaceManagerKey: DependencyKey {
    static let liveValue = SpaceManager(
        readDisplays: {
            do {
                return try ManagedSpacesReader.displays()
            } catch {
                logger.error("Failed to read managed display spaces: \(error)")
                assertionFailure("Failed to read managed display spaces: \(error)")
                return []
            }
        },
        readWindows: { space in
            do {
                return try ManagedSpacesReader.windows(for: space)
            } catch {
                logger.error("Failed to read windows for managed space \(space.managedSpaceID): \(error)")
                assertionFailure("Failed to read windows for managed space \(space.managedSpaceID): \(error)")
                return []
            }
        }
    )

    static let previewValue = SpaceManager(
        readDisplays: {
            [
                ManagedDisplaySpaces(
                    displayIdentifier: "Preview Display",
                    currentSpaceID: 1,
                    spaces: [
                        ManagedSpace(
                            managedSpaceID: 1,
                            id64: 1,
                            uuid: "preview-space-1",
                            type: 0,
                            wsid: 1
                        ),
                        ManagedSpace(
                            managedSpaceID: 2,
                            id64: 2,
                            uuid: "preview-space-2",
                            type: 0,
                            wsid: 2
                        )
                    ]
                )
            ]
        },
        readWindows: { space in
            switch space.managedSpaceID {
            case 1:
                [101, 102, 103]
            case 2:
                [201, 202]
            default:
                []
            }
        }
    )

    static let testValue = SpaceManager(
        readDisplays: {
            []
        },
        readWindows: { _ in
            []
        }
    )
}

extension DependencyValues {
    var spaceManager: SpaceManager {
        get { self[SpaceManagerKey.self] }
        set { self[SpaceManagerKey.self] = newValue }
    }
}
