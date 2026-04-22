//
//  MenuBarContent.swift
//  Plakaki
//
//  Created by Andrey Marshak on 22/04/2026.
//

import Dependencies
import FlightDeck
import GroundControl
import SwiftUI

struct MenuBarContent: View {
    @Dependency(\.appEnumerator) var appEnumerator
    @Dependency(\.spaceManager) var spaceManager
    @Dependency(\.spaceMonitor) var spaceMonitor

    @State private var windowMap: [(ManagedSpace, [ObservedWindow])] = .init()

    var body: some View {
        List {
            ForEach(windowMap, id: \.0) { space, windows in
                Section(space.managedSpaceID.description) {
                    ForEach(windows, id: \.id) { window in
                        Text(window.title ?? window.bundleId ?? "\(window.id)")
                    }
                }
            }
        }.task {
            for await _ in spaceMonitor.activeSpace() {
                let displays = spaceManager.readDisplays()

                let activeSpaces = displays.compactMap { display -> ManagedSpace? in
                    guard let activeSpace = display.currentSpaceID else {
                        return nil
                    }

                    return display.spaces.first { $0.managedSpaceID == activeSpace }
                }

                let currentWindowMap = await appEnumerator.windowMap()
                await MainActor.run {
                    windowMap = activeSpaces.reduce(
                        into: [(ManagedSpace, [ObservedWindow])]()
                    ) { result, space in
                        let windows = spaceManager.readWindows(space)
                            .map { makeWindow(from: $0, windowMap: currentWindowMap) }
                        result.append((space, windows))
                    }
                }
            }
        }
    }

    private func makeWindow(from windowId: CGSWindowID, windowMap: [CGWindowID: AXUIElement]) -> ObservedWindow {
        guard let element = windowMap[windowId] else {
            return ObservedWindow(id: windowId, isTileable: false)
        }

        return ObservedWindow(
            id: windowId,
            bundleId: element.bundleId(),
            title: element.title(),
            isMinimized: element.isMinimized() ?? false
        )
    }
}

#Preview {
    MenuBarContent()
}
