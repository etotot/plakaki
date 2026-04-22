//
//  WorkspaceEventTests.swift
//  FlightDeckTests
//
//  Created by Andrey Marshak on 21/04/2026.
//

@testable import FlightDeck
import Testing

struct WorkspaceEventTests {
    @Test func snapshotChanged() async {
        let graph = WorkspaceGraph(snapshot: .init())

        await graph.handle(EventFixture.Observation.snapshotChanged)

        let root = await graph.snapshot()
        #expect(
            root.displays.map(\.id) == [
                EventFixture.DisplayID.main,
                EventFixture.DisplayID.external
            ]
        )
    }

    // MARK: - Display Events

    @Test func displayConnected() async {
        let graph = WorkspaceGraph(
            snapshot: WorkspaceSnapshot(displays: [EventFixture.Display.main])
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
        let graph = WorkspaceGraph(snapshot: EventFixture.Snapshot.twoDisplays)

        await graph.handle(EventFixture.Observation.displayDisconnected)

        let root = await graph.snapshot()
        #expect(
            root.displays.map(\.id) == [
                EventFixture.DisplayID.main
            ]
        )
    }

    // MARK: - Space Events

    @Test func activeSpaceChanged() async {
        let graph = WorkspaceGraph(
            snapshot: WorkspaceSnapshot(displays: [EventFixture.Display.main])
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
            snapshot: EventFixture.Snapshot.oneDisplayOneSpace
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
            snapshot: EventFixture.Snapshot.oneDisplayTwoSpaces
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

    // MARK: - Window Events

    @Test func windowDiscovered() async {
        let graph = WorkspaceGraph(snapshot: EventFixture.Snapshot.oneDisplayEmptySpace)

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
        let graph = WorkspaceGraph(snapshot: EventFixture.Snapshot.oneDisplayOneSpace)

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
        let graph = WorkspaceGraph(snapshot: EventFixture.Snapshot.oneDisplayOneSpace)

        await graph.handle(EventFixture.Observation.windowRemoved)

        let root = await graph.snapshot()
        #expect(
            root.displays[0].spaces[0].tiledRoot == nil
        )
    }

    @Test func windowMoved() async {
        let graph = WorkspaceGraph(snapshot: EventFixture.Snapshot.oneDisplayTwoSpaces)

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

    // MARK: - Commands

    @Test func focusWindow() async {
        let graph = WorkspaceGraph(snapshot: EventFixture.CommandSnapshot.windowFocusTarget)

        var root = await graph.snapshot()
        #expect(root.displays[0].spaces[0].focusedWindow == nil)

        await graph.handle(EventFixture.Command.focusWindow)

        root = await graph.snapshot()
        #expect(root.displays[0].spaces[0].focusedWindow == EventFixture.WindowID.terminal)
    }

    @Test func focusSpace() async {
        let graph = WorkspaceGraph(snapshot: EventFixture.CommandSnapshot.spaceFocusTarget)

        var root = await graph.snapshot()
        #expect(root.displays[0].focusedSpaceId == EventFixture.SpaceID.primary)

        await graph.handle(EventFixture.Command.focusSpace)

        root = await graph.snapshot()
        #expect(root.displays[0].focusedSpaceId == EventFixture.SpaceID.secondary)
    }

    @Test func focusDisplay() async {
        let graph = WorkspaceGraph(snapshot: EventFixture.CommandSnapshot.displayFocusTarget)

        var root = await graph.snapshot()
        #expect(root.focusedDisplayId == EventFixture.DisplayID.main)

        await graph.handle(EventFixture.Command.focusDisplay)

        root = await graph.snapshot()
        #expect(root.focusedDisplayId == EventFixture.DisplayID.external)
    }

    @Test func toggleFloating() async {
        let graph = WorkspaceGraph(snapshot: EventFixture.CommandSnapshot.floatingToggleTarget)

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
        static let terminal = "terminal"
        static let browser = "browser"
    }

    enum Window {
        static let terminal = ObservedWindow(
            id: WindowID.terminal,
            state: ObservedWindowState(title: "Terminal")
        )

        static let updatedTerminal = ObservedWindow(
            id: WindowID.terminal,
            state: ObservedWindowState(title: "Terminal Updated")
        )

        static let browser = ObservedWindow(
            id: WindowID.browser,
            state: ObservedWindowState(title: "Browser")
        )
    }

    enum Space {
        static let empty = ObservedSpace(id: SpaceID.primary)

        static let primary = ObservedSpace(
            id: SpaceID.primary,
            windows: [Window.terminal]
        )

        static let primaryWithTwoWindows = ObservedSpace(
            id: SpaceID.primary,
            windows: [
                Window.terminal,
                Window.browser
            ]
        )

        static let secondary = ObservedSpace(
            id: SpaceID.secondary,
            windows: [Window.browser]
        )
    }

    enum Display {
        static let mainWithEmptySpace = ObservedDisplay(
            id: DisplayID.main,
            activeSpaceId: SpaceID.primary,
            spaces: [Space.empty]
        )

        static let main = ObservedDisplay(
            id: DisplayID.main,
            activeSpaceId: SpaceID.primary,
            spaces: [Space.primary]
        )

        static let mainWithTwoWindowSpace = ObservedDisplay(
            id: DisplayID.main,
            activeSpaceId: SpaceID.primary,
            spaces: [Space.primaryWithTwoWindows]
        )

        static let mainWithTwoSpaces = ObservedDisplay(
            id: DisplayID.main,
            activeSpaceId: SpaceID.primary,
            spaces: [
                Space.primary,
                Space.secondary
            ]
        )

        static let external = ObservedDisplay(
            id: DisplayID.external,
            activeSpaceId: SpaceID.secondary,
            spaces: [Space.secondary]
        )
    }

    enum Snapshot {
        static let oneDisplayEmptySpace = WorkspaceSnapshot(
            displays: [Display.mainWithEmptySpace]
        )

        static let oneDisplayOneSpace = WorkspaceSnapshot(
            displays: [Display.main]
        )

        static let oneDisplayTwoWindowSpace = WorkspaceSnapshot(
            displays: [Display.mainWithTwoWindowSpace]
        )

        static let oneDisplayTwoSpaces = WorkspaceSnapshot(
            displays: [Display.mainWithTwoSpaces]
        )

        static let twoDisplays = WorkspaceSnapshot(
            displays: [
                Display.main,
                Display.external
            ]
        )
    }

    enum CommandSnapshot {
        static let windowFocusTarget = Snapshot.oneDisplayTwoWindowSpace
        static let spaceFocusTarget = Snapshot.oneDisplayTwoSpaces
        static let displayFocusTarget = Snapshot.twoDisplays
        static let floatingToggleTarget = Snapshot.oneDisplayOneSpace
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
            .windowUpdated(Window.updatedTerminal, spaceId: SpaceID.primary)
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
