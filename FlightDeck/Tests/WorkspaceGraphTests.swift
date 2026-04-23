//
//  WorkspaceGraphTests.swift
//  FlightDeckTests
//
//  Created by Andrey Marshak on 21/04/2026.
//

@testable import FlightDeck
import GroundControl
import Testing

struct WorkspaceGraphTests {
    @Test func displayIdIsPreserved() async {
        let graph = WorkspaceGraph(workspace: Fixture.Workspace.multipleDisplays)
        let root = await graph.snapshot()

        #expect(root.displays[0].id == Fixture.DisplayID.main)
        #expect(root.displays[1].id == Fixture.DisplayID.external)
    }

    @Test func spaceIdIsPreserved() async {
        let graph = WorkspaceGraph(workspace: Fixture.Workspace.emptySpace)
        let root = await graph.snapshot()

        #expect(root.displays[0].spaces[0].id == Fixture.SpaceID.primary)
    }

    @Test func activeSpaceBecomesFocusedSpace() async {
        let graph = WorkspaceGraph(workspace: Fixture.Workspace.activeSecondarySpace)
        let root = await graph.snapshot()

        #expect(root.displays[0].focusedSpaceId == Fixture.SpaceID.secondary)
    }

    @Test func spacesArePreservedInOrder() async {
        let graph = WorkspaceGraph(workspace: Fixture.Workspace.activeSecondarySpace)
        let root = await graph.snapshot()

        #expect(
            root.displays[0].spaces.map(\.id) == [
                Fixture.SpaceID.primary,
                Fixture.SpaceID.secondary
            ]
        )
    }

    @Test func emptySpaceCreatesNoTiledRoot() async {
        let graph = WorkspaceGraph(workspace: Fixture.Workspace.emptySpace)
        let root = await graph.snapshot()

        #expect(root.displays[0].spaces[0].tiledRoot == nil)
    }

    @Test func singleWindowSpaceCreatesStack() async {
        let graph = WorkspaceGraph(workspace: Fixture.Workspace.oneTileableWindow)
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
        let graph = WorkspaceGraph(workspace: Fixture.Workspace.multipleTileableWindows)
        let root = await graph.snapshot()

        let tiledRoot = root.displays[0].spaces[0].tiledRoot
        #expect(
            tiledRoot
                == .stack(
                    direction: .horizontal,
                    children: [
                        .leaf(windowId: Fixture.WindowID.terminal),
                        .leaf(windowId: Fixture.WindowID.browser),
                        .leaf(windowId: Fixture.WindowID.notes)
                    ]
                )
        )
    }

    @Test func spaceWithoutTileableWindowsIsEmpty() async {
        let graph = WorkspaceGraph(workspace: Fixture.Workspace.noTileableWindows)
        let root = await graph.snapshot()

        #expect(root.displays[0].spaces[0].tiledRoot == nil)
    }

    @Test func nonTileableWindowsAreFiltered() async {
        let graph = WorkspaceGraph(workspace: Fixture.Workspace.mixedWindows)
        let root = await graph.snapshot()

        let tiledRoot = root.displays[0].spaces[0].tiledRoot
        #expect(
            tiledRoot
                == .stack(
                    direction: .horizontal,
                    children: [
                        .leaf(windowId: Fixture.WindowID.terminal),
                        .leaf(windowId: Fixture.WindowID.browser)
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
        static let terminal: WindowId = 1001
        static let browser: WindowId = 1002
        static let notes: WindowId = 1003
        static let minimized: WindowId = 1004
        static let dialog: WindowId = 1005
    }

    enum WindowFixture {
        static let terminal = GroundControl.Window(
            id: WindowID.terminal,
            bundleID: "com.example.terminal",
            title: "Terminal"
        )

        static let browser = GroundControl.Window(
            id: WindowID.browser,
            bundleID: "com.example.browser",
            title: "Browser"
        )

        static let notes = GroundControl.Window(
            id: WindowID.notes,
            bundleID: "com.example.notes",
            title: "Notes"
        )

        static let minimized = GroundControl.Window(
            id: WindowID.minimized,
            bundleID: "com.example.minimized",
            title: "Minimized",
            isMinimized: true
        )

        static let dialog = GroundControl.Window(
            id: WindowID.dialog,
            bundleID: "com.example.dialog",
            title: "Dialog",
            isTileable: false
        )
    }

    enum SpaceFixture {
        static let empty = GroundControl.Space(id: SpaceID.primary, windowLookupID: nil, windows: [])

        static let secondary = GroundControl.Space(id: SpaceID.secondary, windowLookupID: nil, windows: [])

        static let oneTileableWindow = GroundControl.Space(
            id: SpaceID.primary,
            windowLookupID: nil,
            windows: [WindowFixture.terminal]
        )

        static let multipleTileableWindows = GroundControl.Space(
            id: SpaceID.primary,
            windowLookupID: nil,
            windows: [
                WindowFixture.terminal,
                WindowFixture.browser,
                WindowFixture.notes
            ]
        )

        static let noTileableWindows = GroundControl.Space(
            id: SpaceID.primary,
            windowLookupID: nil,
            windows: [
                WindowFixture.minimized,
                WindowFixture.dialog
            ]
        )

        static let mixedWindows = GroundControl.Space(
            id: SpaceID.primary,
            windowLookupID: nil,
            windows: [
                WindowFixture.terminal,
                WindowFixture.minimized,
                WindowFixture.dialog,
                WindowFixture.browser
            ]
        )
    }

    enum DisplayFixture {
        static let oneSpace = GroundControl.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.empty],
            focusedSpaceID: SpaceID.primary
        )

        static let activeSecondarySpace = GroundControl.Display(
            id: DisplayID.main,
            spaces: [
                SpaceFixture.empty,
                SpaceFixture.secondary
            ],
            focusedSpaceID: SpaceID.secondary
        )

        static let external = GroundControl.Display(
            id: DisplayID.external,
            spaces: [SpaceFixture.secondary],
            focusedSpaceID: SpaceID.secondary
        )
    }

    enum Workspace {
        static let emptySpace = singleDisplayWorkspace(space: SpaceFixture.empty)

        static let oneTileableWindow = singleDisplayWorkspace(
            space: SpaceFixture.oneTileableWindow
        )

        static let multipleTileableWindows = singleDisplayWorkspace(
            space: SpaceFixture.multipleTileableWindows
        )

        static let noTileableWindows = singleDisplayWorkspace(
            space: SpaceFixture.noTileableWindows
        )

        static let mixedWindows = singleDisplayWorkspace(space: SpaceFixture.mixedWindows)

        static let activeSecondarySpace = GroundControl.Workspace(
            displays: [DisplayFixture.activeSecondarySpace]
        )

        static let multipleDisplays = GroundControl.Workspace(
            displays: [
                DisplayFixture.oneSpace,
                DisplayFixture.external
            ]
        )
    }

    static func singleDisplayWorkspace(space: GroundControl.Space) -> GroundControl.Workspace {
        GroundControl.Workspace(
            displays: [
                GroundControl.Display(
                    id: DisplayID.main,
                    spaces: [space],
                    focusedSpaceID: space.id
                )
            ]
        )
    }
}
