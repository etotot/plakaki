import Dependencies
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
                    spaceManager: spaceManager
                ).makeSnapshot()

                print(snapshot)
            }

            DisplaysView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(appEnumerator: .init())
    }
}
