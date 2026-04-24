//
//  LayoutContainerTests.swift
//  FlightDeckTests
//
//  Created by Codex on 24/04/2026.
//

@testable import FlightDeck
import GroundControl
import Testing

struct LayoutContainerTests {
    @Test func insertingIntoLeafCreatesHorizontalStack() {
        let container = Fixture.Container.leafTerminal.inserting(
            child: .leaf(windowId: Fixture.WindowID.browser)
        )

        #expect(
            container == .stack(direction: .horizontal, children: [
                .leaf(windowId: Fixture.WindowID.terminal),
                .leaf(windowId: Fixture.WindowID.browser)
            ])
        )
    }

    @Test func insertingIntoStackAppendsChildAndPreservesDirection() {
        let container = Fixture.Container.verticalPair.inserting(
            child: .leaf(windowId: Fixture.WindowID.notes)
        )

        #expect(
            container == .stack(direction: .vertical, children: [
                .leaf(windowId: Fixture.WindowID.terminal),
                .leaf(windowId: Fixture.WindowID.browser),
                .leaf(windowId: Fixture.WindowID.notes)
            ])
        )
    }

    @Test func removingOnlyLeafReturnsNil() {
        let container = Fixture.Container.leafTerminal.removing(windowId: Fixture.WindowID.terminal)

        #expect(container == nil)
    }

    @Test func removingMissingWindowReturnsSameContainer() {
        let container = Fixture.Container.horizontalTriple.removing(windowId: Fixture.WindowID.missing)

        #expect(container == Fixture.Container.horizontalTriple)
    }

    @Test func removingFromStackPreservesSurvivorOrder() {
        let container = Fixture.Container.horizontalTriple.removing(windowId: Fixture.WindowID.browser)

        #expect(
            container == .stack(direction: .horizontal, children: [
                .leaf(windowId: Fixture.WindowID.terminal),
                .leaf(windowId: Fixture.WindowID.notes)
            ])
        )
    }

    @Test func movingMissingWindowReturnsSameContainer() {
        let container = Fixture.Container.horizontalTriple.moving(
            windowID: Fixture.WindowID.missing,
            toIndex: 0
        )

        #expect(container == Fixture.Container.horizontalTriple)
    }

    @Test func movingWindowToEarlierIndexReordersChildren() {
        let container = Fixture.Container.horizontalTriple.moving(
            windowID: Fixture.WindowID.notes,
            toIndex: 0
        )

        #expect(
            container == .stack(direction: .horizontal, children: [
                .leaf(windowId: Fixture.WindowID.notes),
                .leaf(windowId: Fixture.WindowID.terminal),
                .leaf(windowId: Fixture.WindowID.browser)
            ])
        )
    }

    @Test func movingWindowToLaterIndexReordersChildren() {
        let container = Fixture.Container.horizontalTriple.moving(
            windowID: Fixture.WindowID.terminal,
            toIndex: 3
        )

        #expect(
            container == .stack(direction: .horizontal, children: [
                .leaf(windowId: Fixture.WindowID.browser),
                .leaf(windowId: Fixture.WindowID.notes),
                .leaf(windowId: Fixture.WindowID.terminal)
            ])
        )
    }

    @Test func windowIDsReflectCurrentOrder() {
        #expect(
            Fixture.Container.horizontalTriple.windowIDs() == [
                Fixture.WindowID.terminal,
                Fixture.WindowID.browser,
                Fixture.WindowID.notes
            ]
        )
    }

    @Test func containsReturnsTrueOnlyForPresentWindows() {
        #expect(Fixture.Container.horizontalTriple.contains(windowId: Fixture.WindowID.browser))
        #expect(!Fixture.Container.horizontalTriple.contains(windowId: Fixture.WindowID.missing))
    }
}

private enum Fixture {
    enum WindowID {
        static let terminal: GroundControl.Window.ID = 1001
        static let browser: GroundControl.Window.ID = 1002
        static let notes: GroundControl.Window.ID = 1003
        static let missing: GroundControl.Window.ID = 1999
    }

    enum Container {
        static let leafTerminal = FlightDeck.Container.leaf(windowId: WindowID.terminal)

        static let verticalPair = FlightDeck.Container.stack(direction: .vertical, children: [
            .leaf(windowId: WindowID.terminal),
            .leaf(windowId: WindowID.browser)
        ])

        static let horizontalTriple = FlightDeck.Container.stack(direction: .horizontal, children: [
            .leaf(windowId: WindowID.terminal),
            .leaf(windowId: WindowID.browser),
            .leaf(windowId: WindowID.notes)
        ])
    }
}
