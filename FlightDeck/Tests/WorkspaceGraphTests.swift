//
//  WorkspaceGraphTests.swift
//  FlightDeckTests
//
//  Created by Andrey Marshak on 21/04/2026.
//

import Testing
@testable import FlightDeck

struct WorkspaceGraphTests {

}

private enum Fixture {
    enum DisplayID {
        static let main = "main-display"
    }

    enum SpaceID {
        static let primary: UInt64 = 1
        static let secondary: UInt64 = 2
    }

    enum WindowID {
        static let terminal = "terminal"
        static let browser = "browser"
        static let notes = "notes"
        static let minimized = "minimized"
        static let dialog = "dialog"
    }

    enum Window {
        static let terminal = ObservedWindow(
            id: WindowID.terminal,
            state: ObservedWindowState(title: "Terminal")
        )

        static let browser = ObservedWindow(
            id: WindowID.browser,
            state: ObservedWindowState(title: "Browser")
        )

        static let notes = ObservedWindow(
            id: WindowID.notes,
            state: ObservedWindowState(title: "Notes")
        )

        static let minimized = ObservedWindow(
            id: WindowID.minimized,
            state: ObservedWindowState(
                title: "Minimized",
                isMinimized: true
            )
        )

        static let dialog = ObservedWindow(
            id: WindowID.dialog,
            state: ObservedWindowState(
                title: "Dialog",
                isTileable: false
            )
        )
    }

    enum Space {
        static let empty = ObservedSpace(id: SpaceID.primary)

        static let oneTileableWindow = ObservedSpace(
            id: SpaceID.primary,
            windows: [Window.terminal]
        )

        static let multipleTileableWindows = ObservedSpace(
            id: SpaceID.primary,
            windows: [
                Window.terminal,
                Window.browser,
                Window.notes
            ]
        )

        static let noTileableWindows = ObservedSpace(
            id: SpaceID.primary,
            windows: [
                Window.minimized,
                Window.dialog
            ]
        )

        static let mixedWindows = ObservedSpace(
            id: SpaceID.primary,
            windows: [
                Window.terminal,
                Window.minimized,
                Window.dialog,
                Window.browser
            ]
        )
    }

    enum Snapshot {
        static let emptySpace = singleDisplaySnapshot(space: Space.empty)

        static let oneTileableWindow = singleDisplaySnapshot(
            space: Space.oneTileableWindow
        )

        static let multipleTileableWindows = singleDisplaySnapshot(
            space: Space.multipleTileableWindows
        )

        static let noTileableWindows = singleDisplaySnapshot(
            space: Space.noTileableWindows
        )

        static let mixedWindows = singleDisplaySnapshot(space: Space.mixedWindows)
    }

    static func singleDisplaySnapshot(space: ObservedSpace) -> WorkspaceSnapshot {
        WorkspaceSnapshot(
            displays: [
                ObservedDisplay(
                    id: DisplayID.main,
                    activeSpaceId: space.id,
                    spaces: [space]
                )
            ]
        )
    }
}
