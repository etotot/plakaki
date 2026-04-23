//
//  DisplayGeometry.swift
//  Plakaki
//
//  Created by Andrey Marshak on 22/04/2026.
//

import AppKit
import ApplicationServices
import FlightDeck
import GroundControl

// MARK: - NSScreen UUID

private typealias CGDisplayCreateUUIDFn = @convention(c) (CGDirectDisplayID) -> Unmanaged<CFUUID>?

private let cgDisplayCreateUUID: CGDisplayCreateUUIDFn? = {
    guard let sym = dlsym(dlopen(nil, RTLD_LAZY), "CGDisplayCreateUUIDFromDisplayID") else {
        return nil
    }
    return unsafeBitCast(sym, to: CGDisplayCreateUUIDFn.self)
}()

extension NSScreen {
    var displayIdentifier: String? {
        guard let fn = cgDisplayCreateUUID,
              let displayID = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
              let uuid = fn(displayID)?.takeRetainedValue()
        else {
            return nil
        }
        return CFUUIDCreateString(nil, uuid) as String?
    }
}

// MARK: - Geometry builder

enum DisplayGeometry {
    static func spaceGeometry(for displays: [FlightDeck.Display]) -> [FlightDeck.Space.ID: CGRect] {
        let screensByIdentifier = Dictionary(
            uniqueKeysWithValues: NSScreen.screens.compactMap { screen -> (String, NSScreen)? in
                guard let id = screen.displayIdentifier else { return nil }
                return (id, screen)
            }
        )

        var result: [GroundControl.Space.ID: CGRect] = [:]
        for display in displays {
            guard let screen = screensByIdentifier[display.id] else { continue }
            let frame = screen.visibleFrame

            for space in display.spaces {
                result[space.id] = frame
            }
        }

        return result
    }
}
