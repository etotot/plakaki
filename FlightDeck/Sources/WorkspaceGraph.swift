//
//  WorkspaceGraph.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 21/04/2026.
//

public actor WorkspaceGraph {
    private var root: Root

    public init(snapshot: WorkspaceSnapshot) {
        root = Self.transform(snapshot: snapshot)
    }

    func snapshot() -> Root {
        root
    }

    // MARK: - Event Handling

    public func handle(_ event: WorkspaceEvent) {
        switch event {
        case let .command(command):
            handle(command: command)
        case let .observation(observation):
            handle(observation: observation)
        }
    }

    private func handle(command: WorkspaceCommand) {
        switch command {
        case let .focusWindow(windowId):
            root.focusWindow(windowId)
        case let .focusSpace(spaceId, displayId):
            root.setFocusedSpaceId(spaceId, displayId: displayId)
        case let .focusDisplay(displayId):
            guard root.displays.contains(where: { $0.id == displayId }) else {
                return
            }

            root.focusedDisplayId = displayId
        case let .toggleFloating(windowId):
            toggleFloating(windowId)
        }
    }

    private func toggleFloating(_ windowId: WindowId) {
        // TODO: This naive full graph scan is fine for now, but we should
        // likely maintain a windowId -> location index once move/remove gets hot.
        for displayIndex in root.displays.indices {
            for spaceIndex in root.displays[displayIndex].spaces.indices {
                if root.displays[displayIndex].spaces[spaceIndex].floatingWindowIds.contains(windowId) {
                    root.displays[displayIndex].spaces[spaceIndex].floatingWindowIds.removeAll { $0 == windowId }
                    root.displays[displayIndex].spaces[spaceIndex].appendTiledWindow(windowId)
                    return
                }

                guard root.displays[displayIndex].spaces[spaceIndex].windowIds.contains(windowId) else {
                    continue
                }

                root.displays[displayIndex].spaces[spaceIndex].removeWindow(windowId)
                root.displays[displayIndex].spaces[spaceIndex].floatingWindowIds.append(windowId)
                return
            }
        }
    }

    private func handle(observation: WorkspaceObservation) {
        switch observation {
        case let .snapshotChanged(newSnapshot):
            root = Self.transform(snapshot: newSnapshot)
            return

        case let .displayConnected(display):
            root.append(display: Self.transform(display: display))

        case let .displayDisconnected(displayId):
            root.remove(displayId: displayId)

        case let .activeSpaceChanged(displayId, spaceId):
            root.setFocusedSpaceId(spaceId, displayId: displayId)

        case let .spaceAdded(space, displayId):
            root.append(space: Self.transform(space: space), displayId: displayId)

        case let .spaceRemoved(spaceId, displayId):
            root.remove(spaceId: spaceId, displayId: displayId)

        case let .windowDiscovered(window, spaceId):
            guard window.state.isTileable, !window.state.isMinimized else {
                return
            }

            root.appendTiledWindow(window.id, spaceId: spaceId)

        case let .windowUpdated(window, spaceId):
            if window.state.isTileable, !window.state.isMinimized {
                root.appendTiledWindow(window.id, spaceId: spaceId)
            } else {
                root.removeWindow(window.id)
            }

        case let .windowRemoved(windowId):
            root.removeWindow(windowId)

        case let .windowMoved(windowId, fromSpaceId, toSpaceId):
            root.moveWindow(
                windowId,
                fromSpaceId: fromSpaceId,
                toSpaceId: toSpaceId
            )
        }
    }

    // MARK: - Graph Conversion

    // TODO: Consider moving to separate file

    private static func transform(snapshot: WorkspaceSnapshot) -> Root {
        Root(
            displays: snapshot.displays.map { transform(display: $0) },
            focusedDisplayId: snapshot.displays.first?.id
        )
    }

    private static func transform(display: ObservedDisplay) -> Display {
        Display(
            id: display.id,
            spaces: display.spaces.map { transform(space: $0) },
            focusedSpaceId: display.activeSpaceId
        )
    }

    private static func transform(space: ObservedSpace) -> Space {
        Space(
            id: space.id,
            tiledRoot: transform(windows: space.windows),
            floatingWindowIds: [], // TODO: Will have to apply floating rules there when supported
            focusedWindow: nil
        )
    }

    private static func transform(windows: [ObservedWindow]) -> Container? {
        let tiledWindows = windows.filter {
            $0.state.isTileable && !$0.state.isMinimized
        }

        guard !tiledWindows.isEmpty else {
            return nil
        }

        return .stack(
            direction: .horizontal,
            children: tiledWindows.map { .leaf(windowId: $0.id) }
        )
    }
}
