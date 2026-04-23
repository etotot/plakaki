import Foundation

public typealias CGSConnectionID = UInt32
public typealias CGSWindowID = UInt32
public typealias CGSSpaceID = UInt64

public struct CGSSpaceQueryMask: OptionSet, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let includesCurrent = Self(rawValue: 1 << 0)
    public static let includesOthers = Self(rawValue: 1 << 1)
    public static let includesUser = Self(rawValue: 1 << 2)

    public static let allSpaces: Self = [
        .includesCurrent,
        .includesOthers,
        .includesUser
    ]
}

public enum CGSPrivateAPIError: Error, CustomStringConvertible, Sendable {
    case missingSymbol(String)
    case unexpectedReturnType(String)
    case malformedManagedDisplayEntry
    case malformedManagedSpaceEntry

    public var description: String {
        switch self {
        case let .missingSymbol(symbol):
            "Missing private SkyLight/CGS symbol: \(symbol)"
        case let .unexpectedReturnType(name):
            "Unexpected return type from private API call: \(name)"
        case .malformedManagedDisplayEntry:
            "Managed display payload did not contain the expected keys"
        case .malformedManagedSpaceEntry:
            "Managed space payload did not contain the expected keys"
        }
    }
}
