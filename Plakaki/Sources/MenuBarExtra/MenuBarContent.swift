//
//  MenuBarContent.swift
//  Plakaki
//
//  Created by Andrey Marshak on 22/04/2026.
//

import Dependencies
import FlightDeck
import GroundControl
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "xyz.etotot.Plakaki", category: "menuBar")

struct MenuBarContent: View {
    @Dependency(\.appEnumerator) var appEnumerator
    @Dependency(\.spaceManager) var spaceManager
    @Dependency(\.spaceMonitor) var spaceMonitor

    @State private var windowMap: [(ManagedSpace, [ObservedWindow])] = .init()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(windowMap, id: \.0) { space, windows in
                    Text("Space \(space.managedSpaceID)")
                        .bold()
                    ForEach(windows, id: \.id) { window in
                        Text(window.title ?? window.bundleId ?? "\(window.id)")
                            .padding(.leading)
                    }
                }
            }
            .padding()
        }
        .frame(width: 300, height: 400)
        .task {
            await appEnumerator.enumerateApps()
            await refresh()
            for await _ in spaceMonitor.activeSpace() {
                await refresh()
            }
        }
    }

    private func refresh() async {
        let displays = spaceManager.readDisplays()
        logger.debug("refresh: \(displays.count) displays")
        let activeSpaces = displays.compactMap { display -> ManagedSpace? in
            guard let activeSpace = display.currentSpaceID else { return nil }
            return display.spaces.first { $0.managedSpaceID == activeSpace }
        }
        logger.debug("refresh: \(activeSpaces.count) active spaces")
        let currentWindowMap = await appEnumerator.windowMap()
        logger.debug("refresh: \(currentWindowMap.count) windows in map")
        for space in activeSpaces {
            let ids = spaceManager.readWindows(space)
            logger.debug("refresh: space \(space.managedSpaceID) has \(ids.count) window IDs")
        }
        await MainActor.run {
            windowMap = activeSpaces.reduce(into: [(ManagedSpace, [ObservedWindow])]()) { result, space in
                let windows = spaceManager.readWindows(space)
                    .map { makeWindow(from: $0, windowMap: currentWindowMap) }
                result.append((space, windows))
            }
        }
    }

    private func makeWindow(from windowId: CGSWindowID, windowMap: [CGWindowID: AXUIElement]) -> ObservedWindow {
        logger.debug("makeWindow: \(windowId) found=\(windowMap[windowId] != nil)")
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
