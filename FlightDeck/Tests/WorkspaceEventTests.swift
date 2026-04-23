//
//  WorkspaceEventTests.swift
//  FlightDeckTests
//
//  Created by Andrey Marshak on 21/04/2026.
//

@testable import FlightDeck
import GroundControl
import Testing

struct WorkspaceEventTests {
    @Test func snapshotChanged() async {
        let graph = WorkspaceGraph(workspace: .init(displays: []))

        await graph.handle(EventFixture.Observation.snapshotChanged)

        let root = await graph.snapshot()
        #expect(
            root.displays.map(\.id) == [
                EventFixture.DisplayID.main,
                EventFixture.DisplayID.external
            ]
        )
    }

    @Test func displayConnected() async {
        let graph = WorkspaceGraph(
            workspace: GroundControl.Workspace(displays: [EventFixture.DisplayFixture.main])
        )

        await graph.handle(EventFixture.Observation.displayConnected)

        let root = await graph.snapshot()
        #expect(
            root.displays.map(\.id) == [
                EventFixture.DisplayID.main,
                EventFixture.DisplayID.external
            ]
        )
    }

    @Test func displayDisconnected() async {
        let graph = WorkspaceGraph(workspace: EventFixture.WorkspaceFixture.twoDisplays)

        await graph.handle(EventFixture.Observation.displayDisconnected)

        let root = await graph.snapshot()
        #expect(
            root.displays.map(\.id) == [
                EventFixture.DisplayID.main
            ]
        )
    }

    @Test func activeSpaceChanged() async {
        let graph = WorkspaceGraph(
            workspace: GroundControl.Workspace(displays: [EventFixture.DisplayFixture.main])
        )

        var root = await graph.snapshot()
        #expect(
            root.displays[0].focusedSpaceId == EventFixture.SpaceID.primary
        )

        await graph.handle(EventFixture.Observation.activeSpaceChanged)

        root = await graph.snapshot()
        #expect(
            root.displays[0].focusedSpaceId == EventFixture.SpaceID.secondary
        )
    }

    @Test func spaceAdded() async {
        let graph = WorkspaceGraph(
            workspace: EventFixture.WorkspaceFixture.oneDisplayOneSpace
        )

        await graph.handle(EventFixture.Observation.spaceAdded)

        let root = await graph.snapshot()
        #expect(
            root.displays[0].spaces.count == 2
        )
        #expect(
            root.displays[0].spaces[1].id == EventFixture.SpaceID.secondary
        )
    }

    @Test func spaceRemoved() async {
        let graph = WorkspaceGraph(
            workspace: EventFixture.WorkspaceFixture.oneDisplayTwoSpaces
        )

        await graph.handle(EventFixture.Observation.spaceRemoved)

        let root = await graph.snapshot()
        #expect(
            root.displays[0].spaces.count == 1
        )
        #expect(
            root.displays[0].spaces[0].id == EventFixture.SpaceID.primary
        )
    }

    @Test func windowDiscovered() async {
        let graph = WorkspaceGraph(workspace: EventFixture.WorkspaceFixture.oneDisplayEmptySpace)

        await graph.handle(EventFixture.Observation.windowDiscovered)

        let root = await graph.snapshot()
        #expect(
            root.displays[0].spaces[0].tiledRoot
                == .stack(
                    direction: .horizontal,
                    children: [
                        .leaf(windowId: EventFixture.WindowID.terminal)
                    ]
                )
        )
    }

    @Test func windowUpdated() async {
        let graph = WorkspaceGraph(workspace: EventFixture.WorkspaceFixture.oneDisplayOneSpace)

        await graph.handle(EventFixture.Observation.windowUpdated)

        let root = await graph.snapshot()
        #expect(
            root.displays[0].spaces[0].tiledRoot
                == .stack(
                    direction: .horizontal,
                    children: [
                        .leaf(windowId: EventFixture.WindowID.terminal)
                    ]
                )
        )
    }

    @Test func windowRemoved() async {
        let graph = WorkspaceGraph(workspace: EventFixture.WorkspaceFixture.oneDisplayOneSpace)

        await graph.handle(EventFixture.Observation.windowRemoved)

        let root = await graph.snapshot()
        #expect(
            root.displays[0].spaces[0].tiledRoot == nil
        )
    }

    @Test func windowMoved() async {
        let graph = WorkspaceGraph(workspace: EventFixture.WorkspaceFixture.oneDisplayTwoSpaces)

        await graph.handle(EventFixture.Observation.windowMoved)

        let root = await graph.snapshot()
        #expect(
            root.displays[0].spaces[1].tiledRoot
                == .stack(
                    direction: .horizontal,
                    children: [
                        .leaf(windowId: EventFixture.WindowID.browser),
                        .leaf(windowId: EventFixture.WindowID.terminal)
                    ]
                )
        )
    }

    @Test func focusWindow() async {
        let graph = WorkspaceGraph(workspace: EventFixture.CommandWorkspace.windowFocusTarget)

        var root = await graph.snapshot()
        #expect(root.displays[0].spaces[0].focusedWindow == nil)

        await graph.handle(EventFixture.Command.focusWindow)

        root = await graph.snapshot()
        #expect(root.displays[0].spaces[0].focusedWindow == EventFixture.WindowID.terminal)
    }

    @Test func focusSpace() async {
        let graph = WorkspaceGraph(workspace: EventFixture.CommandWorkspace.spaceFocusTarget)

        var root = await graph.snapshot()
        #expect(root.displays[0].focusedSpaceId == EventFixture.SpaceID.primary)

        await graph.handle(EventFixture.Command.focusSpace)

        root = await graph.snapshot()
        #expect(root.displays[0].focusedSpaceId == EventFixture.SpaceID.secondary)
    }

    @Test func focusDisplay() async {
        let graph = WorkspaceGraph(workspace: EventFixture.CommandWorkspace.displayFocusTarget)

        var root = await graph.snapshot()
        #expect(root.focusedDisplayId == EventFixture.DisplayID.main)

        await graph.handle(EventFixture.Command.focusDisplay)

        root = await graph.snapshot()
        #expect(root.focusedDisplayId == EventFixture.DisplayID.external)
    }

    @Test func toggleFloating() async {
        let graph = WorkspaceGraph(workspace: EventFixture.CommandWorkspace.floatingToggleTarget)

        var root = await graph.snapshot()
        #expect(root.displays[0].spaces[0].floatingWindowIds.isEmpty)

        await graph.handle(EventFixture.Command.toggleFloating)

        root = await graph.snapshot()
        #expect(root.displays[0].spaces[0].floatingWindowIds == [EventFixture.WindowID.terminal])
    }
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
        static let terminal: WindowId = 1001
        static let browser: WindowId = 1002
    }

    enum WindowFixture {
        static let terminal = GroundControl.Window(
            id: WindowID.terminal,
            bundleID: "com.example.terminal",
            title: "Terminal"
        )

        static let updatedTerminal = GroundControl.Window(
            id: WindowID.terminal,
            bundleID: "com.example.terminal",
            title: "Terminal Updated"
        )

        static let browser = GroundControl.Window(
            id: WindowID.browser,
            bundleID: "com.example.browser",
            title: "Browser"
        )
    }

    enum SpaceFixture {
        static let empty = GroundControl.Space(id: SpaceID.primary, windowLookupID: nil, windows: [])

        static let primary = GroundControl.Space(
            id: SpaceID.primary,
            windowLookupID: nil,
            windows: [WindowFixture.terminal]
        )

        static let primaryWithTwoWindows = GroundControl.Space(
            id: SpaceID.primary,
            windowLookupID: nil,
            windows: [
                WindowFixture.terminal,
                WindowFixture.browser
            ]
        )

        static let secondary = GroundControl.Space(
            id: SpaceID.secondary,
            windowLookupID: nil,
            windows: [WindowFixture.browser]
        )
    }

    enum DisplayFixture {
        static let mainWithEmptySpace = GroundControl.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.empty],
            focusedSpaceID: SpaceID.primary
        )

        static let main = GroundControl.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.primary],
            focusedSpaceID: SpaceID.primary
        )

        static let mainWithTwoWindowSpace = GroundControl.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.primaryWithTwoWindows],
            focusedSpaceID: SpaceID.primary
        )

        static let mainWithTwoSpaces = GroundControl.Display(
            id: DisplayID.main,
            spaces: [
                SpaceFixture.primary,
                SpaceFixture.secondary
            ],
            focusedSpaceID: SpaceID.primary
        )

        static let external = GroundControl.Display(
            id: DisplayID.external,
            spaces: [SpaceFixture.secondary],
            focusedSpaceID: SpaceID.secondary
        )
    }

    enum WorkspaceFixture {
        static let oneDisplayEmptySpace = GroundControl.Workspace(
            displays: [DisplayFixture.mainWithEmptySpace]
        )

        static let oneDisplayOneSpace = GroundControl.Workspace(
            displays: [DisplayFixture.main]
        )

        static let oneDisplayTwoWindowSpace = GroundControl.Workspace(
            displays: [DisplayFixture.mainWithTwoWindowSpace]
        )

        static let oneDisplayTwoSpaces = GroundControl.Workspace(
            displays: [DisplayFixture.mainWithTwoSpaces]
        )

        static let twoDisplays = GroundControl.Workspace(
            displays: [
                DisplayFixture.main,
                DisplayFixture.external
            ]
        )
    }

    enum CommandWorkspace {
        static let windowFocusTarget = WorkspaceFixture.oneDisplayTwoWindowSpace
        static let spaceFocusTarget = WorkspaceFixture.oneDisplayTwoSpaces
        static let displayFocusTarget = WorkspaceFixture.twoDisplays
        static let floatingToggleTarget = WorkspaceFixture.oneDisplayOneSpace
    }

    enum Observation {
        static let snapshotChanged = WorkspaceEvent.observation(
            .snapshotChanged(WorkspaceFixture.twoDisplays)
        )

        static let displayConnected = WorkspaceEvent.observation(
            .displayConnected(DisplayFixture.external)
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
            .spaceAdded(SpaceFixture.secondary, displayId: DisplayID.main)
        )

        static let spaceRemoved = WorkspaceEvent.observation(
            .spaceRemoved(SpaceID.secondary, displayId: DisplayID.main)
        )

        static let windowDiscovered = WorkspaceEvent.observation(
            .windowDiscovered(WindowFixture.terminal, spaceId: SpaceID.primary)
        )

        static let windowUpdated = WorkspaceEvent.observation(
            .windowUpdated(WindowFixture.updatedTerminal, spaceId: SpaceID.primary)
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
