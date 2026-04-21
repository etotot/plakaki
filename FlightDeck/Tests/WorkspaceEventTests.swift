//
//  WorkspaceEventTests.swift
//  FlightDeckTests
//
//  Created by Andrey Marshak on 21/04/2026.
//

import Testing

@testable import FlightDeck

struct WorkspaceEventTests {
}

private enum EventFixture {
    enum DisplayID {
        static let main = "main-display"
        static let external = "external-display"
    }

    enum SpaceID {
        static let primary: UInt64 = 1
        static let secondary: UInt64 = 2
    }

    enum WindowID {
        static let terminal = "terminal"
        static let browser = "browser"
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
    }

    enum Space {
        static let primary = ObservedSpace(
            id: SpaceID.primary,
            windows: [Window.terminal]
        )

        static let secondary = ObservedSpace(
            id: SpaceID.secondary,
            windows: [Window.browser]
        )
    }

    enum Display {
        static let main = ObservedDisplay(
            id: DisplayID.main,
            activeSpaceId: SpaceID.primary,
            spaces: [Space.primary]
        )

        static let external = ObservedDisplay(
            id: DisplayID.external,
            activeSpaceId: SpaceID.secondary,
            spaces: [Space.secondary]
        )
    }

    enum Snapshot {
        static let twoDisplays = WorkspaceSnapshot(
            displays: [
                Display.main,
                Display.external,
            ]
        )
    }

    enum Observation {
        static let snapshotChanged = WorkspaceEvent.observation(
            .snapshotChanged(Snapshot.twoDisplays)
        )

        static let displayConnected = WorkspaceEvent.observation(
            .displayConnected(Display.external)
        )

        static let displayDisconnected = WorkspaceEvent.observation(
            .displayDisconnected(DisplayID.external)
        )

        static let activeSpaceChanged = WorkspaceEvent.observation(
            .activeSpaceChanged(
                displayId: DisplayID.main,
                spaceId: SpaceID.secondary
            )
        )

        static let spaceAdded = WorkspaceEvent.observation(
            .spaceAdded(Space.secondary, displayId: DisplayID.main)
        )

        static let spaceRemoved = WorkspaceEvent.observation(
            .spaceRemoved(SpaceID.secondary, displayId: DisplayID.main)
        )

        static let windowDiscovered = WorkspaceEvent.observation(
            .windowDiscovered(Window.terminal, spaceId: SpaceID.primary)
        )

        static let windowUpdated = WorkspaceEvent.observation(
            .windowUpdated(Window.terminal, spaceId: SpaceID.primary)
        )

        static let windowRemoved = WorkspaceEvent.observation(
            .windowRemoved(WindowID.terminal)
        )

        static let windowMoved = WorkspaceEvent.observation(
            .windowMoved(
                windowId: WindowID.terminal,
                fromSpaceId: SpaceID.primary,
                toSpaceId: SpaceID.secondary
            )
        )
    }

    enum Command {
        static let focusWindow = WorkspaceEvent.command(
            .focusWindow(WindowID.terminal)
        )

        static let focusSpace = WorkspaceEvent.command(
            .focusSpace(SpaceID.secondary, displayId: DisplayID.main)
        )

        static let focusDisplay = WorkspaceEvent.command(
            .focusDisplay(DisplayID.external)
        )

        static let toggleFloating = WorkspaceEvent.command(
            .toggleFloating(WindowID.terminal)
        )
    }
}
