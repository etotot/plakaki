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
    @Dependency(\.workspaceMonitor) var workspaceMonitor

    @State private var windowMap: [(GroundControl.Space, [GroundControl.Window])] = .init()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(windowMap, id: \.0) { space, windows in
                    Text("Space \(space.id)")
                        .bold()

                    ForEach(windows, id: \.id) { window in
                        Text(title(for: window))
                    }
                }
            }
            .padding()
        }
        .frame(width: 300, height: 400)
        .task {
            await refresh(workspaceMonitor.readWorkspace())

            for await workspace in await workspaceMonitor.workspaces() {
                await refresh(workspace)
            }
        }
    }

    private func refresh(_ workspace: Workspace) async {
        let displays = workspace.displays
        logger.debug("refresh: \(displays.count) displays")

        let activeSpaces = displays.compactMap { display -> GroundControl.Space? in
            let activeSpace = display.focusedSpaceID
            return display.spaces.first { $0.id == activeSpace }
        }
        logger.debug("refresh: \(activeSpaces.count) active spaces")

        await MainActor.run {
            windowMap = activeSpaces.reduce(into: [(GroundControl.Space, [GroundControl.Window])]()) { result, space in
                let windows = space.windows
                result.append((space, windows))
            }
        }
    }

    private func title(for window: GroundControl.Window) -> String {
        "\(window.bundleID ?? "<no bundleID>") | \(window.title ?? "<no title>") | \(window.id)"
    }
}

#Preview {
    MenuBarContent()
}
