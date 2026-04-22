//
//  LayoutEngineTests.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 22/04/2026.
//

import CoreGraphics
@testable import FlightDeck
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
        static let terminal: WindowId = 1001
        static let browser: WindowId = 1002
        static let notes: WindowId = 1003
    }

    enum Frame {
        static let display = CGRect(x: 0, y: 0, width: 1000, height: 800)
        static let external = CGRect(x: 1000, y: 0, width: 2560, height: 1440)
    }

    enum Geometry {
        static let main: [Space.ID: CGRect] = [SpaceID.primary: Frame.display]
        static let empty: [Space.ID: CGRect] = [:]
        static let twoDisplays: [Space.ID: CGRect] = [
            SpaceID.primary: Frame.display,
            SpaceID.secondary: Frame.external
        ]
    }

    enum SpaceFixture {
        static let empty = FlightDeck.Space(id: SpaceID.primary)

        static let oneTiledWindow = FlightDeck.Space(
            id: SpaceID.primary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal)
            ])
        )

        static let twoTiledWindows = FlightDeck.Space(
            id: SpaceID.primary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal),
                .leaf(windowId: WindowID.browser)
            ])
        )

        static let threeTiledWindows = FlightDeck.Space(
            id: SpaceID.primary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal),
                .leaf(windowId: WindowID.browser),
                .leaf(windowId: WindowID.notes)
            ])
        )

        static let nestedStack = FlightDeck.Space(
            id: SpaceID.primary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal),
                .stack(direction: .horizontal, children: [
                    .leaf(windowId: WindowID.browser),
                    .leaf(windowId: WindowID.notes)
                ])
            ])
        )

        static let focusedMiddleWindow = FlightDeck.Space(
            id: SpaceID.primary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal),
                .leaf(windowId: WindowID.browser),
                .leaf(windowId: WindowID.notes)
            ]),
            focusedWindow: WindowID.browser
        )

        static let nonFocused = FlightDeck.Space(
            id: SpaceID.secondary,
            tiledRoot: .stack(direction: .horizontal, children: [
                .leaf(windowId: WindowID.terminal)
            ])
        )
    }

    enum DisplayFixture {
        static let empty = FlightDeck.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.empty],
            focusedSpaceId: SpaceID.primary
        )

        static let oneTiledWindow = FlightDeck.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.oneTiledWindow],
            focusedSpaceId: SpaceID.primary
        )

        static let twoTiledWindows = FlightDeck.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.twoTiledWindows],
            focusedSpaceId: SpaceID.primary
        )

        static let threeTiledWindows = FlightDeck.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.threeTiledWindows],
            focusedSpaceId: SpaceID.primary
        )

        static let nestedStack = FlightDeck.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.nestedStack],
            focusedSpaceId: SpaceID.primary
        )

        static let focusedMiddleWindow = FlightDeck.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.focusedMiddleWindow],
            focusedSpaceId: SpaceID.primary
        )

        static let nonFocusedSpaceHasWindows = FlightDeck.Display(
            id: DisplayID.main,
            spaces: [SpaceFixture.empty, SpaceFixture.nonFocused],
            focusedSpaceId: SpaceID.primary
        )

        static let external = FlightDeck.Display(
            id: DisplayID.external,
            spaces: [SpaceFixture.oneTiledWindow],
            focusedSpaceId: SpaceID.secondary
        )
    }

    enum RootFixture {
        static let empty = Root()

        static let emptyDisplay = Root(displays: [DisplayFixture.empty])

        static let oneTiledWindow = Root(displays: [DisplayFixture.oneTiledWindow])

        static let twoTiledWindows = Root(displays: [DisplayFixture.twoTiledWindows])

        static let threeTiledWindows = Root(displays: [DisplayFixture.threeTiledWindows])

        static let nestedStack = Root(displays: [DisplayFixture.nestedStack])

        static let focusedMiddleWindow = Root(displays: [DisplayFixture.focusedMiddleWindow])

        static let nonFocusedSpaceHasWindows = Root(displays: [DisplayFixture.nonFocusedSpaceHasWindows])

        static let missingGeometry = Root(displays: [DisplayFixture.oneTiledWindow])
    }
}
