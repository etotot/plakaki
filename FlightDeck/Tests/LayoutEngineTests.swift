//
//  LayoutEngineTests.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 22/04/2026.
//

import CoreGraphics
@testable import FlightDeck
import GroundControl
import Testing

struct LayoutEngineTests {
    // MARK: - Empty / skip cases

    @Test func emptyRootProducesEmptyPlan() {
        let plan = LayoutEngine.computeLayout(for: Fixture.RootFixture.empty, spaceGeometry: Fixture.Geometry.empty)
        #expect(plan.windows.isEmpty)
    }

    @Test func emptyFocusedSpaceProducesEmptyPlan() {
        let plan = LayoutEngine.computeLayout(
            for: Fixture.RootFixture.emptyDisplay,
            spaceGeometry: Fixture.Geometry.main
        )
        #expect(plan.windows.isEmpty)
    }

    @Test func missingGeometrySkipsDisplay() {
        let plan = LayoutEngine.computeLayout(
            for: Fixture.RootFixture.missingGeometry,
            spaceGeometry: Fixture.Geometry.empty
        )
        #expect(plan.windows.isEmpty)
    }

    @Test func nonFocusedSpaceIsIgnored() {
        let plan = LayoutEngine.computeLayout(
            for: Fixture.RootFixture.nonFocusedSpaceHasWindows,
            spaceGeometry: Fixture.Geometry.main
        )
        #expect(plan.windows.isEmpty)
    }

    // MARK: - Tiled layout

    @Test func singleWindowFillsDisplayFrame() {
        let plan = LayoutEngine.computeLayout(
            for: Fixture.RootFixture.oneTiledWindow,
            spaceGeometry: Fixture.Geometry.main
        )
        #expect(plan.windows[Fixture.WindowID.terminal]?.frame == Fixture.Frame.display)
    }

    @Test func twoWindowsSplitWidthEvenly() {
        let plan = LayoutEngine.computeLayout(
            for: Fixture.RootFixture.twoTiledWindows,
            spaceGeometry: Fixture.Geometry.main
        )
        // (1000 - 8) / 2 = 496; x[1] = 496 + 8 = 504
        #expect(plan.windows[Fixture.WindowID.terminal]?.frame == CGRect(x: 0, y: 0, width: 496, height: 800))
        #expect(plan.windows[Fixture.WindowID.browser]?.frame == CGRect(x: 504, y: 0, width: 496, height: 800))
    }

    @Test func threeWindowsSplitWidthEvenly() {
        let plan = LayoutEngine.computeLayout(
            for: Fixture.RootFixture.threeTiledWindows,
            spaceGeometry: Fixture.Geometry.main
        )
        // (1000 - 16) / 3 = 328; x[1] = 336, x[2] = 672
        #expect(plan.windows[Fixture.WindowID.terminal]?.frame == CGRect(x: 0, y: 0, width: 328, height: 800))
        #expect(plan.windows[Fixture.WindowID.browser]?.frame == CGRect(x: 336, y: 0, width: 328, height: 800))
        #expect(plan.windows[Fixture.WindowID.notes]?.frame == CGRect(x: 672, y: 0, width: 328, height: 800))
    }

    @Test func nestedStackLayoutsRecursively() {
        let plan = LayoutEngine.computeLayout(
            for: Fixture.RootFixture.nestedStack,
            spaceGeometry: Fixture.Geometry.main
        )
        // Outer split: left=496, right offset=504 width=496
        // Right child splits: (496 - 8) / 2 = 244; x[0]=504, x[1]=504+244+8=756
        #expect(plan.windows[Fixture.WindowID.terminal]?.frame == CGRect(x: 0, y: 0, width: 496, height: 800))
        #expect(plan.windows[Fixture.WindowID.browser]?.frame == CGRect(x: 504, y: 0, width: 244, height: 800))
        #expect(plan.windows[Fixture.WindowID.notes]?.frame == CGRect(x: 756, y: 0, width: 244, height: 800))
    }

    // MARK: - zIndex

    @Test func unfocusedTiledWindowsGetZIndexZero() {
        let plan = LayoutEngine.computeLayout(
            for: Fixture.RootFixture.oneTiledWindow,
            spaceGeometry: Fixture.Geometry.main
        )
        #expect(plan.windows[Fixture.WindowID.terminal]?.zIndex == 0)
    }

    @Test func focusedTiledWindowGetHigherZIndex() {
        let plan = LayoutEngine.computeLayout(
            for: Fixture.RootFixture.focusedMiddleWindow,
            spaceGeometry: Fixture.Geometry.main
        )
        #expect(plan.windows[Fixture.WindowID.terminal]?.zIndex == 0)
        #expect(plan.windows[Fixture.WindowID.browser]?.zIndex == 1)
        #expect(plan.windows[Fixture.WindowID.notes]?.zIndex == 0)
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
        static let terminal: GroundControl.Window.ID = 1001
        static let browser: GroundControl.Window.ID = 1002
        static let notes: GroundControl.Window.ID = 1003
    }

    enum Frame {
        static let display = CGRect(x: 0, y: 0, width: 1000, height: 800)
        static let external = CGRect(x: 1000, y: 0, width: 2560, height: 1440)
    }

    enum Geometry {
        static let main: [GroundControl.Space.ID: CGRect] = [SpaceID.primary: Frame.display]
        static let empty: [GroundControl.Space.ID: CGRect] = [:]
        static let twoDisplays: [GroundControl.Space.ID: CGRect] = [
            SpaceID.primary: Frame.display,
            SpaceID.secondary: Frame.external
        ]
    }

    enum SpaceFixture {
        static let empty = FlightDeck.LayoutSpace(id: SpaceID.primary)

        static let oneTiledWindow = FlightDeck.LayoutSpace(
            id: SpaceID.primary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal)
            ])
        )

        static let twoTiledWindows = FlightDeck.LayoutSpace(
            id: SpaceID.primary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal),
                .leaf(windowId: WindowID.browser)
            ])
        )

        static let threeTiledWindows = FlightDeck.LayoutSpace(
            id: SpaceID.primary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal),
                .leaf(windowId: WindowID.browser),
                .leaf(windowId: WindowID.notes)
            ])
        )

        static let nestedStack = FlightDeck.LayoutSpace(
            id: SpaceID.primary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal),
                .stack(direction: .horizontal, children: [
                    .leaf(windowId: WindowID.browser),
                    .leaf(windowId: WindowID.notes)
                ])
            ])
        )

        static let focusedMiddleWindow = FlightDeck.LayoutSpace(
            id: SpaceID.primary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal),
                .leaf(windowId: WindowID.browser),
                .leaf(windowId: WindowID.notes)
            ]),
            focusedWindow: WindowID.browser
        )

        static let nonFocused = FlightDeck.LayoutSpace(
            id: SpaceID.secondary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal)
            ])
        )
    }

    enum DisplayFixture {
        static let empty = FlightDeck.LayoutDisplay(
            id: DisplayID.main,
            spaces: [SpaceFixture.empty],
            focusedSpaceID: SpaceID.primary
        )

        static let oneTiledWindow = FlightDeck.LayoutDisplay(
            id: DisplayID.main,
            spaces: [SpaceFixture.oneTiledWindow],
            focusedSpaceID: SpaceID.primary
        )

        static let twoTiledWindows = FlightDeck.LayoutDisplay(
            id: DisplayID.main,
            spaces: [SpaceFixture.twoTiledWindows],
            focusedSpaceID: SpaceID.primary
        )

        static let threeTiledWindows = FlightDeck.LayoutDisplay(
            id: DisplayID.main,
            spaces: [SpaceFixture.threeTiledWindows],
            focusedSpaceID: SpaceID.primary
        )

        static let nestedStack = FlightDeck.LayoutDisplay(
            id: DisplayID.main,
            spaces: [SpaceFixture.nestedStack],
            focusedSpaceID: SpaceID.primary
        )

        static let focusedMiddleWindow = FlightDeck.LayoutDisplay(
            id: DisplayID.main,
            spaces: [SpaceFixture.focusedMiddleWindow],
            focusedSpaceID: SpaceID.primary
        )

        static let nonFocusedSpaceHasWindows = FlightDeck.LayoutDisplay(
            id: DisplayID.main,
            spaces: [SpaceFixture.empty, SpaceFixture.nonFocused],
            focusedSpaceID: SpaceID.primary
        )

        static let external = FlightDeck.LayoutDisplay(
            id: DisplayID.external,
            spaces: [SpaceFixture.oneTiledWindow],
            focusedSpaceID: SpaceID.secondary
        )
    }

    enum RootFixture {
        static let empty = LayoutRoot()

        static let emptyDisplay = LayoutRoot(displays: [DisplayFixture.empty])

        static let oneTiledWindow = LayoutRoot(displays: [DisplayFixture.oneTiledWindow])

        static let twoTiledWindows = LayoutRoot(displays: [DisplayFixture.twoTiledWindows])

        static let threeTiledWindows = LayoutRoot(displays: [DisplayFixture.threeTiledWindows])

        static let nestedStack = LayoutRoot(displays: [DisplayFixture.nestedStack])

        static let focusedMiddleWindow = LayoutRoot(displays: [DisplayFixture.focusedMiddleWindow])

        static let nonFocusedSpaceHasWindows = LayoutRoot(displays: [DisplayFixture.nonFocusedSpaceHasWindows])

        static let missingGeometry = LayoutRoot(displays: [DisplayFixture.oneTiledWindow])
    }
}
