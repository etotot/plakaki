import Dependencies
import FlightDeck
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "xyz.etotot.Plakaki", category: "contentView")

public struct ContentView: View {
    @Dependency(\.axPermissionManager) var axPermissionManager
    @Dependency(\.workspaceMonitor) var workspaceMonitor

    public var body: some View {
        VStack {
            Text("Hello, World!")
                .padding()

            Button(
                action: {
                    _ = axPermissionManager.isTrusted(true)
                },
                label: {
                    Text("Check ax permissions")
                }
            )

            Button("Start app Monitoring") {
                Task { await workspaceMonitor.enumerateApplications() }
            }

            Button("Print workspace") {
                Task {
                    let workspace = await workspaceMonitor.readWorkspace()
                    logger.debug("Workspace: \(String(describing: workspace))")
                }
            }

            Button("Apply layout") {
                Task {
                    let workspace = await workspaceMonitor.readWorkspace()

                    let graph = WorkspaceGraph(workspace: workspace)
                    let root = await graph.snapshot()

                    let geometry = DisplayGeometry.spaceGeometry(for: root.displays)
                    logger.debug("Geometry: \(String(describing: geometry))")

                    let plan = LayoutEngine.computeLayout(for: root, spaceGeometry: geometry)
                    logger.debug("Layout plan: \(plan.windows.count) windows")

                    for (windowId, layout) in plan.windows {
                        await workspaceMonitor.setFrame(layout.frame, windowId)
                    }
                }
            }

            DisplaysView()
        }
    }

    func applyLayout() {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
