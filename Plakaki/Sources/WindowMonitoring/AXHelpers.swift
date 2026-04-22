@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import Foundation
import GroundControl

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
        try unpackAXValue(for: attribute, as: .cgPoint, initialValue: CGPoint.zero)
    }

    func size(for attribute: CFString) throws -> CGSize {
        try unpackAXValue(for: attribute, as: .cgSize, initialValue: CGSize.zero)
    }

    func rect() throws -> CGRect {
        try CGRect(
            origin: point(for: kAXPositionAttribute as CFString),
            size: size(for: kAXSizeAttribute as CFString)
        )
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

    func title() -> String? {
        optionalValue(for: kAXTitleAttribute as CFString)
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

    private func unpackAXValue<T>(
        for attribute: CFString,
        as axType: AXValueType,
        initialValue: T
    ) throws -> T {
        let axValue: AXValue = try value(for: attribute)
        var unpackedValue = initialValue

        guard AXValueGetValue(axValue, axType, &unpackedValue) else {
            throw AXHelperError.invalidAXValue(attribute)
        }

        return unpackedValue
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

struct ApplicationSnapshot {
    let processIdentifier: pid_t
    let bundleIdentifier: String?
    let localizedName: String?
    let isActive: Bool
    let axElement: AXUIElement

    init(application: NSRunningApplication) {
        processIdentifier = application.processIdentifier
        bundleIdentifier = application.bundleIdentifier
        localizedName = application.localizedName
        isActive = application.isActive
        axElement = AXUIElement.application(application)
    }
}

struct WindowSnapshot {
    let axElement: AXUIElement
    let application: ApplicationSnapshot
    let title: String?
    let frame: CGRect
    let role: String?
    let subrole: String?
    let isMinimized: Bool?
}

enum AXDiscoverySource: String {
    case windows
    case focusedWindow
    case mainWindow
}

extension AXUIElement {
    func snapshot(for application: ApplicationSnapshot) throws -> WindowSnapshot {
        try WindowSnapshot(
            axElement: self,
            application: application,
            title: title(),
            frame: rect(),
            role: role(),
            subrole: subrole(),
            isMinimized: isMinimized()
        )
    }

    func discoverWindows() -> [AXUIElement] {
        let windowList = (try? windows()) ?? []
        let fallbackWindows = [
            focusedWindow(),
            mainWindow()
        ].compactMap(\.self)

        return deduplicatedAXElements(windowList + fallbackWindows)
    }
}
