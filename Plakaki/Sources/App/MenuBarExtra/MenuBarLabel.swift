//
//  MenuBarLabel.swift
//  Plakaki
//
//  Created by Andrey Marshak on 22/04/2026.
//

import Dependencies
import GroundControl
import SwiftUI

struct MenuBarLabel: View {
    @Dependency(\.workspaceMonitor) var workspaceMonitor

    @State private var label: String = "·"

    var body: some View {
        Text(label)
            .task {
                for await workspace in await workspaceMonitor.workspaces() {
                    let displays = workspace.displays
                    await MainActor.run {
                        label = Self.makeLabel(for: displays)
                    }
                }
            }
    }

    private static func makeLabel(for displays: [GroundControl.Display]) -> String {
        displays
            .filter { !$0.spaces.isEmpty }
            .map { display in
                let tokens = display.spaces.enumerated().map { index, space in
                    let number = "\(index + 1)"
                    return space.id == display.focusedSpaceID ? "[\(number)]" : number
                }
                return tokens.joined(separator: " ")
            }
            .joined(separator: "  ")
    }
}
