//
//  DisplaysView.swift
//  GroundControl
//
//  Created by Andrey Marshak on 20/04/2026.
//

import Dependencies
import GroundControl
import Observation
import SwiftUI

@MainActor
@Observable
private final class DisplaysViewModel {
    @ObservationIgnored @Dependency(\.spaceManager) var spaceManager

    var displays: [ManagedDisplaySpaces] = []
    var selectedDisplayIdentifier: String?

    var selectedDisplay: ManagedDisplaySpaces? {
        guard let selectedDisplayIdentifier else { return displays.first }
        return displays.first { $0.displayIdentifier == selectedDisplayIdentifier }
    }

    var spaces: [ManagedSpace] {
        selectedDisplay?.spaces ?? []
    }

    init() {
        self.displays = spaceManager.readDisplays()
        self.selectedDisplayIdentifier = displays.first?.displayIdentifier
    }
}

struct DisplaysView: View {
    @State private var viewModel = DisplaysViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Screens", selection: $viewModel.selectedDisplayIdentifier) {
                    ForEach(viewModel.displays, id: \.displayIdentifier) { display in
                        Text(display.displayIdentifier)
                            .tag(Optional(display.displayIdentifier))
                    }
                }

                List {
                    ForEach(viewModel.spaces, id: \.managedSpaceID) { space in
                        NavigationLink(value: space) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Space \(space.managedSpaceID)")
                                Text(space.uuid ?? "No UUID")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Displays")
            .navigationDestination(for: ManagedSpace.self) { space in
                SpacesView(space: space)
            }
        }
    }
}

#Preview {
    DisplaysView()
}
