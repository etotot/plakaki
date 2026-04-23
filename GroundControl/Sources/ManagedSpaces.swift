import Foundation

public enum ManagedSpacesReader {
    public static func workspace() throws -> _Workspace {
        let displays = try displays()
        return _Workspace(
            displays: displays,
            focusedDisplayID: displays.first?.id
        )
    }

    public static func displays() throws -> [_Display] {
        try CGSPrivateAPI.copyManagedDisplaySpaces().map(parseDisplay)
    }

    public static func windows(for space: _Space) throws -> [_Window] {
        guard let windowLookupID = space.windowLookupID else {
            return []
        }

        return try windows(forSpaceID64: windowLookupID)
    }

    public static func windows(forSpaceID64 spaceID64: UInt64) throws -> [_Window] {
        try CGSPrivateAPI.copyWindows(forSpaceID64: spaceID64).map(makeWindow)
    }

    public static func spaces(forWindowID windowID: CGSWindowID) throws -> Set<CGSSpaceID> {
        try Set(CGSPrivateAPI.copySpacesForWindows([windowID]))
    }

    public static func spaces(forWindowIDs windowIDs: [CGSWindowID]) throws -> [CGSWindowID: Set<CGSSpaceID>] {
        var result: [CGSWindowID: Set<CGSSpaceID>] = [:]

        for windowID in windowIDs {
            result[windowID] = try spaces(forWindowID: windowID)
        }

        return result
    }

    private static func parseDisplay(_ rawDisplay: [String: Any]) throws -> _Display {
        guard let displayIdentifier = rawDisplay["Display Identifier"] as? String else {
            throw CGSPrivateAPIError.malformedManagedDisplayEntry
        }

        let currentSpaceID = parseCurrentSpaceID(rawDisplay["Current Space"])
        let spaces = try (rawDisplay["Spaces"] as? [[String: Any]] ?? []).map(parseSpace)

        return _Display(
            id: displayIdentifier,
            spaces: spaces,
            focusedSpaceID: currentSpaceID ?? spaces.first?.id ?? 0
        )
    }

    private static func parseCurrentSpaceID(_ value: Any?) -> CGSSpaceID? {
        guard let rawCurrentSpace = value as? [String: Any] else {
            return nil
        }

        if let id = (rawCurrentSpace["ManagedSpaceID"] as? NSNumber)?.uint64Value {
            return id
        }

        if let id64 = (rawCurrentSpace["id64"] as? NSNumber)?.uint64Value {
            return id64
        }

        return nil
    }

    private static func parseSpace(_ rawSpace: [String: Any]) throws -> _Space {
        guard let managedSpaceID = (rawSpace["ManagedSpaceID"] as? NSNumber)?.uint64Value else {
            throw CGSPrivateAPIError.malformedManagedSpaceEntry
        }

        let windowLookupID = (rawSpace["id64"] as? NSNumber)?.uint64Value
        let windows = try windowLookupID.map(windows(forSpaceID64:)) ?? []

        return _Space(
            id: managedSpaceID,
            windowLookupID: windowLookupID,
            windows: windows,
            focusedWindowID: nil
        )
    }

    private static func makeWindow(id: CGSWindowID) -> _Window {
        _Window(
            id: id,
            pid: nil,
            bundleID: nil,
            title: nil,
            isMinimized: false,
            isTileable: false
        )
    }
}
