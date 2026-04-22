import Darwin
import Foundation

public enum CGSPrivateAPI {
    private typealias CGSMainConnectionIDFn = @convention(c) () -> CGSConnectionID
    private typealias CGSDefaultConnectionFn = @convention(c) () -> CGSConnectionID
    private typealias CGSCopyManagedDisplaySpacesFn = @convention(c) (CGSConnectionID) -> Unmanaged<CFArray>
    private typealias CGSCopySpacesForWindowsFn =
        @convention(c) (CGSConnectionID, UInt32, CFArray) -> Unmanaged<CFArray>
    private typealias CGSCopyWindowsWithOptionsAndTagsFn =
        @convention(c) (
            CGSConnectionID,
            UInt32,
            CFArray,
            UInt32,
            UnsafeMutablePointer<UInt64>?,
            UnsafeMutablePointer<UInt64>?
        ) -> Unmanaged<CFArray>
    private typealias CGSAddWindowsToSpacesFn = @convention(c) (CGSConnectionID, CFArray, CFArray) -> Void
    private typealias CGSRemoveWindowsFromSpacesFn = @convention(c) (CGSConnectionID, CFArray, CFArray) -> Void
    private typealias SLSMoveWindowsToManagedSpaceFn = @convention(c) (CGSConnectionID, CFArray, CGSSpaceID) -> Int32

    private static let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)

    public static func mainConnectionID() throws -> CGSConnectionID {
        if let function: CGSMainConnectionIDFn = try loadOptionalSymbol(named: "CGSMainConnectionID") {
            return function()
        }

        if let function: CGSDefaultConnectionFn = try loadOptionalSymbol(named: "_CGSDefaultConnection") {
            return function()
        }

        throw CGSPrivateAPIError.missingSymbol("CGSMainConnectionID / _CGSDefaultConnection")
    }

    public static func copyManagedDisplaySpaces() throws -> [[String: Any]] {
        let function: CGSCopyManagedDisplaySpacesFn = try loadSymbol(named: "CGSCopyManagedDisplaySpaces")
        let connection = try mainConnectionID()
        let payload = function(connection).takeRetainedValue()

        guard let displays = payload as? [[String: Any]] else {
            throw CGSPrivateAPIError.unexpectedReturnType("CGSCopyManagedDisplaySpaces")
        }

        return displays
    }

    public static func copySpacesForWindows(
        _ windowIDs: [CGSWindowID],
        mask: CGSSpaceQueryMask = .allSpaces
    ) throws -> [CGSSpaceID] {
        let function: CGSCopySpacesForWindowsFn = try loadSymbol(named: "CGSCopySpacesForWindows")
        let connection = try mainConnectionID()
        let cfWindowIDs = windowIDs.map(NSNumber.init(value:)) as CFArray
        let payload = function(connection, mask.rawValue, cfWindowIDs).takeRetainedValue()

        guard let spaceIDs = payload as? [NSNumber] else {
            throw CGSPrivateAPIError.unexpectedReturnType("CGSCopySpacesForWindows")
        }

        return spaceIDs.map(\.uint64Value)
    }

    public static func copyWindows(
        forSpaceID64 spaceID64: UInt64,
        owner: UInt32 = 0,
        options: UInt32 = 2,
        setTags: UInt64 = 0,
        clearTags: UInt64 = 0x40_0000_0000
    ) throws -> [CGSWindowID] {
        let function: CGSCopyWindowsWithOptionsAndTagsFn =
            try loadSymbol(named: "CGSCopyWindowsWithOptionsAndTags")
        let connection = try mainConnectionID()
        let cfSpaceIDs = [NSNumber(value: spaceID64)] as CFArray
        var mutableSetTags = setTags
        var mutableClearTags = clearTags
        let payload = function(
            connection,
            owner,
            cfSpaceIDs,
            options,
            &mutableSetTags,
            &mutableClearTags
        ).takeRetainedValue()

        guard let windowIDs = payload as? [NSNumber] else {
            throw CGSPrivateAPIError.unexpectedReturnType("CGSCopyWindowsWithOptionsAndTags")
        }

        return windowIDs.map(\.uint32Value)
    }

    public static func addWindows(
        _ windowIDs: [CGSWindowID],
        toSpaces spaceIDs: [CGSSpaceID]
    ) throws {
        let function: CGSAddWindowsToSpacesFn = try loadSymbol(named: "CGSAddWindowsToSpaces")
        let connection = try mainConnectionID()
        let cfWindowIDs = windowIDs.map(NSNumber.init(value:)) as CFArray
        let cfSpaceIDs = spaceIDs.map(NSNumber.init(value:)) as CFArray
        function(connection, cfWindowIDs, cfSpaceIDs)
    }

    public static func removeWindows(
        _ windowIDs: [CGSWindowID],
        fromSpaces spaceIDs: [CGSSpaceID]
    ) throws {
        let function: CGSRemoveWindowsFromSpacesFn = try loadSymbol(named: "CGSRemoveWindowsFromSpaces")
        let connection = try mainConnectionID()
        let cfWindowIDs = windowIDs.map(NSNumber.init(value:)) as CFArray
        let cfSpaceIDs = spaceIDs.map(NSNumber.init(value:)) as CFArray
        function(connection, cfWindowIDs, cfSpaceIDs)
    }

    @discardableResult
    public static func moveWindows(
        _ windowIDs: [CGSWindowID],
        toManagedSpace spaceID: CGSSpaceID
    ) throws -> Int32 {
        let function: SLSMoveWindowsToManagedSpaceFn = try loadSymbol(named: "SLSMoveWindowsToManagedSpace")
        let connection = try mainConnectionID()
        let cfWindowIDs = windowIDs.map(NSNumber.init(value:)) as CFArray
        return function(connection, cfWindowIDs, spaceID)
    }

    private static func loadSymbol<T>(named name: String) throws -> T {
        guard let symbol: T = try loadOptionalSymbol(named: name) else {
            throw CGSPrivateAPIError.missingSymbol(name)
        }

        return symbol
    }

    private static func loadOptionalSymbol<T>(named name: String) throws -> T? {
        guard let handle = rtldDefault,
              let symbol = dlsym(handle, name)
        else {
            return nil
        }

        return unsafeBitCast(symbol, to: T.self)
    }
}
