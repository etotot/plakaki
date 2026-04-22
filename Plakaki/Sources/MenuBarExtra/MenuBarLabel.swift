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
    @Dependency(\.spaceManager) var spaceManager
    @Dependency(\.spaceMonitor) var spaceMonitor

    @State private var label: String = "·"

    var body: some View {
        Text(label)
            .task {
                for await _ in spaceMonitor.activeSpace() {
                    let displays = spaceManager.readDisplays()
                    await MainActor.run {
                        label = Self.makeLabel(for: displays)
                    }
                }
            }
    }

    private static func makeLabel(for displays: [ManagedDisplaySpaces]) -> String {
        displays
            .filter { !$0.spaces.isEmpty }
            .map { display in
                let tokens = display.spaces.enumerated().map { index, space in
                    let number = "\(index + 1)"
                    return space.managedSpaceID == display.currentSpaceID ? "[\(number)]" : number
                }
                return tokens.joined(separator: " ")
            }
            .joined(separator: "  ")
    }
}
