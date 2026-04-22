import Dependencies
import FlightDeck
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "xyz.etotot.Plakaki", category: "contentView")

public struct ContentView: View {
    @Dependency(\.appEnumerator) var appEnumerator
    @Dependency(\.axPermissionManager) var axPermissionManager
    @Dependency(\.spaceManager) var spaceManager

    public var body: some View {
        VStack {
            Text("Hello, World!")
                .padding()

            Button(
                action: {
                    _ = axPermissionManager.checkAxStatus(true)
                },
                label: {
                    Text("Check ax permissions")
                }
            )

            Button("Start app Monitoring") {
                Task { await appEnumerator.enumerateApps() }
            }

            Button("Print workspace snapshot") {
                Task {
                    let snapshot = await WorkspaceSnapshotBuilder(
                        spaceManager: spaceManager, appEnumerator: appEnumerator
                    ).makeSnapshot()
                    logger.debug("Workspace snapshot: \(String(describing: snapshot))")
                }
            }
            Button("Apply layout") {
                Task {
                    let snapshot = await WorkspaceSnapshotBuilder(
                        spaceManager: spaceManager, appEnumerator: appEnumerator
                    ).makeSnapshot()

                    let graph = WorkspaceGraph(snapshot: snapshot)
                    let root = await graph.snapshot()
                    let geometry = DisplayGeometry.spaceGeometry(for: root.displays)
                    logger.debug("Geometry: \(String(describing: geometry))")
                    let plan = LayoutEngine.computeLayout(for: root, spaceGeometry: geometry)
                    logger.debug("Layout plan: \(plan.windows.count) windows")
                    let windowMap = await appEnumerator.windowMap()
                    for (windowId, layout) in plan.windows {
                        guard let element = windowMap[windowId] else {
                            logger.info("[\(windowId)] no AX element — skipping")
                            continue
                        }
                        let title = element.title() ?? "<no title>"
                        let currentFrame = try? element.rect()
                        logger.debug("[\(windowId)] \(title) current: \(String(describing: currentFrame))")
                        logger.debug("[\(windowId)] target: \(String(describing: layout.frame))")
                        try? element.setFrame(layout.frame)
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
