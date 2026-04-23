//
//  SpacesView.swift
//  GroundControl
//
//  Created by Andrey Marshak on 20/04/2026.
//

import Dependencies
import GroundControl
import Observation
import SwiftUI

struct SpacesView: View {
    @Dependency(\.workspaceMonitor) private var workspaceMonitor

    let space: GroundControl.Space

    @State private var windows: [GroundControl.Window] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Space \(space.id)")
                    .font(.headline)

                Text("\(space.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if windows.isEmpty {
                ContentUnavailableView(
                    "No Windows",
                    systemImage: "macwindow",
                    description: Text("No windows were found in this space.")
                )
            } else {
                List(windows, id: \.self) { window in
                    Text("Window \(window.id)")
                        .font(.body.monospacedDigit())
                }
            }
        }
        .padding()
        .navigationTitle("Space")
        .task(id: space.id) {
            windows = await workspaceMonitor.readWindows(space.id)
        }
        .toolbar {
            Button("Reload") {
                Task {
                    windows = await workspaceMonitor.readWindows(space.id)
                }
            }
        }
    }
}

#Preview {
    SpacesView(
        space: GroundControl.Space(
            id: 0,
            windowLookupID: 0,
            windows: []
        )
    )
}
