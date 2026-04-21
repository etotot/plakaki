//
//  WorkspaceGraphTests.swift
//  FlightDeckTests
//
//  Created by Andrey Marshak on 21/04/2026.
//

import Testing

@testable import FlightDeck

struct WorkspaceGraphTests {
    // MARK: - Display Transformation

    @Test func displayIdIsPreserved() async {
        let graph = WorkspaceGraph(snapshot: Fixture.Snapshot.multipleDisplays)
        let root = await graph.snapshot()

        #expect(root.displays[0].id == "main-display")
        #expect(root.displays[1].id == "external-display")
    }

    // MARK: - Space Transformation

    @Test func spaceIdIsPreserved() async {
        let graph = WorkspaceGraph(snapshot: Fixture.Snapshot.emptySpace)
        let root = await graph.snapshot()

        #expect(root.displays[0].spaces[0].id == 1)
    }

    @Test func activeSpaceBecomesFocusedSpace() async {
        let graph = WorkspaceGraph(snapshot: Fixture.Snapshot.activeSecondarySpace)
        let root = await graph.snapshot()

        #expect(root.displays[0].focusedSpaceId == 2)
    }

    @Test func spacesArePreservedInOrder() async {
        let graph = WorkspaceGraph(snapshot: Fixture.Snapshot.activeSecondarySpace)
        let root = await graph.snapshot()

        #expect(
            root.displays[0].spaces.map(\.id) == [
                Fixture.SpaceID.primary,
                Fixture.SpaceID.secondary,
            ])
    }

    // MARK: - Window Transformation

    @Test func emptySpaceCreatesNoTiledRoot() async {
        let graph = WorkspaceGraph(snapshot: Fixture.Snapshot.emptySpace)
        let root = await graph.snapshot()

        #expect(root.displays[0].spaces[0].tiledRoot == nil)
    }

    @Test func singleWindowSpaceCreatesStack() async {
        let fixture = Fixture.Snapshot.oneTileableWindow
        let graph = WorkspaceGraph(snapshot: fixture)
        let root = await graph.snapshot()

        let tiledRoot = root.displays[0].spaces[0].tiledRoot
        #expect(
            tiledRoot
                == .stack(
                    direction: .horizontal,
                    children: [
                        .leaf(windowId: Fixture.WindowID.terminal)
                    ]
                )
        )
    }

    @Test func multipleWindowSpaceCreatesStack() async {
        let fixture = Fixture.Snapshot.multipleTileableWindows
        let graph = WorkspaceGraph(snapshot: fixture)
        let root = await graph.snapshot()

        let tiledRoot = root.displays[0].spaces[0].tiledRoot
        #expect(
            tiledRoot
                == .stack(
                    direction: .horizontal,
                    children: [
                        .leaf(windowId: Fixture.WindowID.terminal),
                        .leaf(windowId: Fixture.WindowID.browser),
                        .leaf(windowId: Fixture.WindowID.notes),
                    ]
                )
        )
    }

    @Test func spaceWithoutTileableWindowsIsEmpty() async {
        let fixture = Fixture.Snapshot.noTileableWindows
        let graph = WorkspaceGraph(snapshot: fixture)
        let root = await graph.snapshot()

        #expect(root.displays[0].spaces[0].tiledRoot == nil)
    }

    @Test func nonTileableWindowsAreFiltered() async {
        let fixture = Fixture.Snapshot.mixedWindows
        let graph = WorkspaceGraph(snapshot: fixture)
        let root = await graph.snapshot()

        let tiledRoot = root.displays[0].spaces[0].tiledRoot
        #expect(
            tiledRoot
                == .stack(
                    direction: .horizontal,
                    children: [
                        .leaf(windowId: Fixture.WindowID.terminal),
                        .leaf(windowId: Fixture.WindowID.browser),
                    ]
                )
        )
    }
}

private enum Fixture {
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

        static let secondary = ObservedSpace(id: SpaceID.secondary)

        static let oneTileableWindow = ObservedSpace(
            id: SpaceID.primary,
            windows: [Window.terminal]
        )

        static let multipleTileableWindows = ObservedSpace(
            id: SpaceID.primary,
            windows: [
                Window.terminal,
                Window.browser,
                Window.notes,
            ]
        )

        static let noTileableWindows = ObservedSpace(
            id: SpaceID.primary,
            windows: [
                Window.minimized,
                Window.dialog,
            ]
        )

        static let mixedWindows = ObservedSpace(
            id: SpaceID.primary,
            windows: [
                Window.terminal,
                Window.minimized,
                Window.dialog,
                Window.browser,
            ]
        )
    }

    enum Display {
        static let oneSpace = ObservedDisplay(
            id: DisplayID.main,
            activeSpaceId: SpaceID.primary,
            spaces: [Space.empty]
        )

        static let activeSecondarySpace = ObservedDisplay(
            id: DisplayID.main,
            activeSpaceId: SpaceID.secondary,
            spaces: [
                Space.empty,
                Space.secondary,
            ]
        )

        static let external = ObservedDisplay(
            id: DisplayID.external,
            activeSpaceId: SpaceID.secondary,
            spaces: [Space.secondary]
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

        static let activeSecondarySpace = WorkspaceSnapshot(
            displays: [Display.activeSecondarySpace]
        )

        static let multipleDisplays = WorkspaceSnapshot(
            displays: [
                Display.oneSpace,
                Display.external,
            ]
        )
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
