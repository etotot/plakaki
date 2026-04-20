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
    @Dependency(\.spaceManager) private var spaceManager

    let space: ManagedSpace

    @State private var windowIDs: [CGSWindowID] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Space \(space.managedSpaceID)")
                    .font(.headline)

                Text(space.uuid ?? "No UUID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if windowIDs.isEmpty {
                ContentUnavailableView(
                    "No Windows",
                    systemImage: "macwindow",
                    description: Text("No windows were found in this space.")
                )
            } else {
                List(windowIDs, id: \.self) { windowID in
                    Text("Window \(windowID)")
                        .font(.body.monospacedDigit())
                }
            }
        }
        .padding()
        .navigationTitle("Space")
        .task(id: space.managedSpaceID) {
            windowIDs = spaceManager.readWindows(space)
        }
        .toolbar {
            Button("Reload") {
                windowIDs = spaceManager.readWindows(space)
            }
        }
    }
}

#Preview {
    SpacesView(
        space: ManagedSpace(
            managedSpaceID: 1,
            id64: 1,
            uuid: "preview-space-1",
            type: 0,
            wsid: 1
        )
    )
}
