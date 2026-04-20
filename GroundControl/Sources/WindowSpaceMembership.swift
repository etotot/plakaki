import Foundation

public struct WindowSpaceMembershipSnapshot: Sendable {
    public var memberships: [CGSWindowID: Set<CGSSpaceID>]

    public init(memberships: [CGSWindowID: Set<CGSSpaceID>] = [:]) {
        self.memberships = memberships
    }
}

public struct WindowSpaceChange: Hashable, Sendable {
    public let windowID: CGSWindowID
    public let oldSpaces: Set<CGSSpaceID>
    public let newSpaces: Set<CGSSpaceID>

    public init(
        windowID: CGSWindowID,
        oldSpaces: Set<CGSSpaceID>,
        newSpaces: Set<CGSSpaceID>
    ) {
        self.windowID = windowID
        self.oldSpaces = oldSpaces
        self.newSpaces = newSpaces
    }
}

public enum WindowSpaceMembershipTracker {
    public static func snapshot(for windowIDs: [CGSWindowID]) throws -> WindowSpaceMembershipSnapshot {
        WindowSpaceMembershipSnapshot(
            memberships: try ManagedSpacesReader.spaces(forWindowIDs: windowIDs)
        )
    }

    public static func diff(
        old: WindowSpaceMembershipSnapshot,
        new: WindowSpaceMembershipSnapshot
    ) -> [WindowSpaceChange] {
        let allWindowIDs = Set(old.memberships.keys).union(new.memberships.keys)

        return allWindowIDs.compactMap { windowID in
            let oldSpaces = old.memberships[windowID] ?? []
            let newSpaces = new.memberships[windowID] ?? []

            guard oldSpaces != newSpaces else {
                return nil
            }

            return WindowSpaceChange(
                windowID: windowID,
                oldSpaces: oldSpaces,
                newSpaces: newSpaces
            )
        }
    }
}
