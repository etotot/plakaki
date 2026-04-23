@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import Foundation

@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: inout CGSWindowID) -> AXError

enum AXHelperError: Error, CustomStringConvertible {
    case attributeUnsupported(CFString)
    case cannotComplete(CFString)
    case failure(AXError, CFString)
    case typeMismatch(CFString, expected: String)
    case invalidAXValue(CFString)

    var description: String {
        switch self {
        case let .attributeUnsupported(attribute):
            "AX attribute unsupported: \(attribute)"
        case let .cannotComplete(attribute):
            "AX request could not complete for attribute: \(attribute)"
        case let .failure(error, attribute):
            "AX request failed for attribute \(attribute): \(error.rawValue)"
        case let .typeMismatch(attribute, expected):
            "AX attribute \(attribute) did not match expected type \(expected)"
        case let .invalidAXValue(attribute):
            "AX attribute \(attribute) contained an invalid AXValue payload"
        }
    }
}

extension AXUIElement {
    static func application(_ application: NSRunningApplication) -> AXUIElement {
        AXUIElementCreateApplication(application.processIdentifier)
    }

    func value<T>(for attribute: CFString, as type: T.Type = T.self) throws -> T {
        var rawValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(self, attribute, &rawValue)

        switch result {
        case .success:
            guard let typedValue = rawValue as? T else {
                throw AXHelperError.typeMismatch(
                    attribute,
                    expected: String(describing: type)
                )
            }

            return typedValue
        case .attributeUnsupported, .noValue:
            throw AXHelperError.attributeUnsupported(attribute)
        case .cannotComplete:
            throw AXHelperError.cannotComplete(attribute)
        default:
            throw AXHelperError.failure(result, attribute)
        }
    }

    func optionalValue<T>(for attribute: CFString, as type: T.Type = T.self) -> T? {
        try? value(for: attribute, as: type)
    }

    func point(for attribute: CFString) throws -> CGPoint {
        let axValue: AXValue = try value(for: attribute)
        var point = CGPoint.zero

        guard AXValueGetValue(axValue, .cgPoint, &point) else {
            throw AXHelperError.invalidAXValue(attribute)
        }

        return point
    }

    func size(for attribute: CFString) throws -> CGSize {
        let axValue: AXValue = try value(for: attribute)
        var size = CGSize.zero

        guard AXValueGetValue(axValue, .cgSize, &size) else {
            throw AXHelperError.invalidAXValue(attribute)
        }

        return size
    }

    func rect() throws -> CGRect {
        try CGRect(
            origin: point(for: kAXPositionAttribute as CFString),
            size: size(for: kAXSizeAttribute as CFString)
        )
    }

    func setPosition(_ point: CGPoint) throws {
        var mutablePoint = point
        guard let axValue = AXValueCreate(.cgPoint, &mutablePoint) else {
            throw AXHelperError.invalidAXValue(kAXPositionAttribute as CFString)
        }
        let result = AXUIElementSetAttributeValue(self, kAXPositionAttribute as CFString, axValue)
        guard result == .success else {
            throw AXHelperError.failure(result, kAXPositionAttribute as CFString)
        }
    }

    func setSize(_ size: CGSize) throws {
        var mutableSize = size
        guard let axValue = AXValueCreate(.cgSize, &mutableSize) else {
            throw AXHelperError.invalidAXValue(kAXSizeAttribute as CFString)
        }
        let result = AXUIElementSetAttributeValue(self, kAXSizeAttribute as CFString, axValue)
        guard result == .success else {
            throw AXHelperError.failure(result, kAXSizeAttribute as CFString)
        }
    }

    func setFrame(_ rect: CGRect) throws {
        try setPosition(rect.origin)
        try setSize(rect.size)
    }

    func windowID() throws -> CGSWindowID {
        var windowID: CGSWindowID = 0
        let result = _AXUIElementGetWindow(self, &windowID)
        guard result == .success else {
            throw AXHelperError.failure(result, "_AXUIElementGetWindow" as CFString)
        }
        return windowID
    }

    func windows() throws -> [AXUIElement] {
        try value(for: kAXWindowsAttribute as CFString)
    }

    func focusedWindow() -> AXUIElement? {
        optionalValue(for: kAXFocusedWindowAttribute as CFString)
    }

    func mainWindow() -> AXUIElement? {
        optionalValue(for: kAXMainWindowAttribute as CFString)
    }

    public func title() -> String? {
        optionalValue(for: kAXTitleAttribute as CFString)
    }

    func processIdentifier() -> pid_t? {
        var pid: pid_t = 0
        guard AXUIElementGetPid(self, &pid) == .success else { return nil }
        return pid
    }

    func bundleID() -> String? {
        guard let pid = processIdentifier() else { return nil }
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }

    func role() -> String? {
        optionalValue(for: kAXRoleAttribute as CFString)
    }

    func subrole() -> String? {
        optionalValue(for: kAXSubroleAttribute as CFString)
    }

    func isMinimized() -> Bool? {
        optionalValue(for: kAXMinimizedAttribute as CFString)
    }
}

func deduplicatedAXElements(_ elements: [AXUIElement]) -> [AXUIElement] {
    var uniqueElements: [AXUIElement] = []

    for element in elements {
        if uniqueElements.contains(where: { CFEqual($0, element) }) {
            continue
        }

        uniqueElements.append(element)
    }

    return uniqueElements
}

extension AXUIElement {
    func discoverWindows() -> [AXUIElement] {
        let windowList = (try? windows()) ?? []
        let fallbackWindows = [
            focusedWindow(),
            mainWindow()
        ].compactMap(\.self)

        return deduplicatedAXElements(windowList + fallbackWindows)
    }
}
