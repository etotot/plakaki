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
    let appEnumerator: AppEnumerator

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

                await MainActor.run {
                    windowMap = activeSpaces.reduce(
                        into: [(ManagedSpace, [ObservedWindow])]()
                    ) { result, space in
                        result.append((space, spaceManager.readWindows(space).map(makeWindow)))
                    }
                }
            }
        }
    }

    private func makeWindow(from windowId: CGSWindowID) -> ObservedWindow {
        guard let element = appEnumerator.windowMap[windowId] else {
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
    MenuBarContent(appEnumerator: .init())
}
