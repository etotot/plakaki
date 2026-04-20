import Foundation

public struct ManagedSpace: Hashable, Sendable {
    public let managedSpaceID: CGSSpaceID
    public let id64: UInt64?
    public let uuid: String?
    public let type: Int?
    public let wsid: Int?

    public init(
        managedSpaceID: CGSSpaceID,
        id64: UInt64?,
        uuid: String?,
        type: Int?,
        wsid: Int?
    ) {
        self.managedSpaceID = managedSpaceID
        self.id64 = id64
        self.uuid = uuid
        self.type = type
        self.wsid = wsid
    }
}

public struct ManagedDisplaySpaces: Hashable, Sendable {
    public let displayIdentifier: String
    public let currentSpaceID: CGSSpaceID?
    public let spaces: [ManagedSpace]

    public init(
        displayIdentifier: String,
        currentSpaceID: CGSSpaceID?,
        spaces: [ManagedSpace]
    ) {
        self.displayIdentifier = displayIdentifier
        self.currentSpaceID = currentSpaceID
        self.spaces = spaces
    }
}

public enum ManagedSpacesReader {
    public static func displays() throws -> [ManagedDisplaySpaces] {
        try CGSPrivateAPI.copyManagedDisplaySpaces().map(parseDisplay)
    }

    public static func windows(for space: ManagedSpace) throws -> [CGSWindowID] {
        guard let id64 = space.id64 else {
            return []
        }

        return try CGSPrivateAPI.copyWindows(forSpaceID64: id64)
    }

    public static func windows(forSpaceID64 spaceID64: UInt64) throws -> [CGSWindowID] {
        try CGSPrivateAPI.copyWindows(forSpaceID64: spaceID64)
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

    private static func parseDisplay(_ rawDisplay: [String: Any]) throws -> ManagedDisplaySpaces {
        guard let displayIdentifier = rawDisplay["Display Identifier"] as? String else {
            throw CGSPrivateAPIError.malformedManagedDisplayEntry
        }

        let currentSpaceID = parseCurrentSpaceID(rawDisplay["Current Space"])
        let spaces = try (rawDisplay["Spaces"] as? [[String: Any]] ?? []).map(parseSpace)

        return ManagedDisplaySpaces(
            displayIdentifier: displayIdentifier,
            currentSpaceID: currentSpaceID,
            spaces: spaces
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

    private static func parseSpace(_ rawSpace: [String: Any]) throws -> ManagedSpace {
        guard let managedSpaceID = (rawSpace["ManagedSpaceID"] as? NSNumber)?.uint64Value else {
            throw CGSPrivateAPIError.malformedManagedSpaceEntry
        }

        return ManagedSpace(
            managedSpaceID: managedSpaceID,
            id64: (rawSpace["id64"] as? NSNumber)?.uint64Value,
            uuid: rawSpace["uuid"] as? String,
            type: (rawSpace["type"] as? NSNumber)?.intValue,
            wsid: (rawSpace["wsid"] as? NSNumber)?.intValue
        )
    }
}
