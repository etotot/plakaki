//
//  WorkspaceSnapshot.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 21/04/2026.
//

public struct WorkspaceSnapshot: CustomDebugStringConvertible, CustomStringConvertible, Sendable {
    public var displays: [ObservedDisplay]

    public init(displays: [ObservedDisplay] = []) {
        self.displays = displays
    }

    public var description: String {
        debugDescription
    }

    public var debugDescription: String {
        var lines = ["WorkspaceSnapshot"]

        if displays.isEmpty {
            lines.append("  displays: []")
        } else {
            lines.append(contentsOf: displays.flatMap { $0.debugLines(indentation: "  ") })
        }

        return lines.joined(separator: "\n")
    }
}

public struct ObservedDisplay: CustomDebugStringConvertible, CustomStringConvertible, Identifiable,
    Sendable
{
    public var id: Display.ID
    public var activeSpaceId: Space.ID
    public var spaces: [ObservedSpace]

    public init(
        id: Display.ID,
        activeSpaceId: Space.ID,
        spaces: [ObservedSpace] = []
    ) {
        self.id = id
        self.activeSpaceId = activeSpaceId
        self.spaces = spaces
    }

    public var description: String {
        debugDescription
    }

    public var debugDescription: String {
        debugLines(indentation: "").joined(separator: "\n")
    }
}

public struct ObservedSpace: CustomDebugStringConvertible, CustomStringConvertible, Identifiable,
    Sendable
{
    public var id: Space.ID
    public var windows: [ObservedWindow]

    public init(
        id: Space.ID,
        windows: [ObservedWindow] = []
    ) {
        self.id = id
        self.windows = windows
    }

    public var description: String {
        debugDescription
    }

    public var debugDescription: String {
        debugLines(indentation: "").joined(separator: "\n")
    }
}

public struct ObservedWindow: CustomDebugStringConvertible, CustomStringConvertible, Identifiable,
    Sendable
{
    public var id: WindowId
    public var state: ObservedWindowState

    public init(
        id: WindowId,
        state: ObservedWindowState = ObservedWindowState()
    ) {
        self.id = id
        self.state = state
    }

    public var description: String {
        debugDescription
    }

    public var debugDescription: String {
        debugLines(indentation: "").joined(separator: "\n")
    }
}

public struct ObservedWindowState: CustomDebugStringConvertible, CustomStringConvertible, Sendable {
    public var title: String?
    public var isMinimized: Bool
    public var isTileable: Bool

    public init(
        title: String? = nil,
        isMinimized: Bool = false,
        isTileable: Bool = true
    ) {
        self.title = title
        self.isMinimized = isMinimized
        self.isTileable = isTileable
    }

    public var description: String {
        debugDescription
    }

    public var debugDescription: String {
        let titleDescription = title.map { "\"\($0)\"" } ?? "nil"

        return "title: \(titleDescription), minimized: \(isMinimized), tileable: \(isTileable)"
    }
}

private extension ObservedDisplay {
    func debugLines(indentation: String) -> [String] {
        var lines = [
            "\(indentation)Display(id: \(id), activeSpaceId: \(activeSpaceId))"
        ]

        if spaces.isEmpty {
            lines.append("\(indentation)  spaces: []")
        } else {
            lines.append(
                contentsOf: spaces.flatMap { $0.debugLines(indentation: "\(indentation)  ") }
            )
        }

        return lines
    }
}

private extension ObservedSpace {
    func debugLines(indentation: String) -> [String] {
        var lines = ["\(indentation)Space(id: \(id))"]

        if windows.isEmpty {
            lines.append("\(indentation)  windows: []")
        } else {
            lines.append(
                contentsOf: windows.map { $0.debugLines(indentation: "\(indentation)  ") }.flatMap(\.self)
            )
        }

        return lines
    }
}

private extension ObservedWindow {
    func debugLines(indentation: String) -> [String] {
        [
            "\(indentation)Window(id: \(id), \(state.debugDescription))"
        ]
    }
}
