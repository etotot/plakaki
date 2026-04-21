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
        case .command:
            return
        case let .observation(observation):
            handle(observation: observation)
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

        default:
            return
        }
    }

    // MARK: - Graph Conversion

    // TODO: Consider moving to separate file

    private static func transform(snapshot: WorkspaceSnapshot) -> Root {
        Root(
            displays: snapshot.displays.map { transform(display: $0) },
            focusedDisplayId: nil
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
