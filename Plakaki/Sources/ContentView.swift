import Dependencies
import FlightDeck
import SwiftUI

public struct ContentView: View {
    let appEnumerator: AppEnumerator

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
                appEnumerator.enumerateApps()
            }

            Button("Print workspace snapshot") {
                let snapshot = WorkspaceSnapshotBuilder(
                    spaceManager: spaceManager, appEnumerator: appEnumerator
                ).makeSnapshot()

                print(snapshot)
            }
            Button("Apply layout") {
                Task {
                    let snapshot = WorkspaceSnapshotBuilder(
                        spaceManager: spaceManager, appEnumerator: appEnumerator
                    ).makeSnapshot()

                    let graph = WorkspaceGraph(snapshot: snapshot)
                    let root = await graph.snapshot()
                    let geometry = DisplayGeometry.spaceGeometry(for: root.displays)
                    print("Geometry: \(geometry)")
                    let plan = LayoutEngine.computeLayout(for: root, spaceGeometry: geometry)
                    print("Layout plan: \(plan.windows.count) windows")
                    for (windowId, layout) in plan.windows {
                        guard let element = appEnumerator.windowMap[windowId] else {
                            print("  [\(windowId)] no AX element — skipping")
                            continue
                        }
                        let title = element.title() ?? "<no title>"
                        let currentFrame = try? element.rect()
                        print("  [\(windowId)] \(title)")
                        print("    current: \(currentFrame.map { "\($0)" } ?? "unknown")")
                        print("    target:  \(layout.frame)")
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
        ContentView(appEnumerator: .init())
    }
}
