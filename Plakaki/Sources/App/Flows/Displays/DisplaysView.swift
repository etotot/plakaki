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
    @ObservationIgnored @Dependency(\.workspaceMonitor) var workspaceMonitor

    var displays: [Display] = []
    var focusedDisplayID: String?

    var focusedDisplay: GroundControl.Display? {
        guard let focusedDisplayID else { return displays.first }
        return displays.first { $0.id == focusedDisplayID }
    }

    var spaces: [GroundControl.Space] {
        focusedDisplay?.spaces ?? []
    }

    init() {
        displays = []
        focusedDisplayID = displays.first?.id
    }

    func refresh() async {
        let workspace = await workspaceMonitor.readWorkspace()

        displays = workspace.displays
        focusedDisplayID = workspace.focusedDisplayID
    }
}

struct DisplaysView: View {
    @State private var viewModel = DisplaysViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Screens", selection: $viewModel.focusedDisplayID) {
                    ForEach(viewModel.displays) { display in
                        Text(display.id)
                            .tag(Optional(display.id))
                    }
                }

                List {
                    ForEach(viewModel.spaces) { space in
                        NavigationLink(value: space) {
                            VStack(alignment: .leading) {
                                Text("Space \(space.id)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Displays")
            .navigationDestination(for: Space.self) { space in
                SpacesView(space: space)
            }
        }
        .task {
            await viewModel.refresh()
        }
    }
}

#Preview {
    DisplaysView()
}
