import Dependencies
import SwiftUI

public struct ContentView: View {
    @Dependency(\.axPermissionManager) var axPermissionManager

    public var body: some View {
        VStack {
            Text("Hello, World!")
                .padding()

            Button(
                action: {
                    self.axPermissionManager.checkAxStatus(true)
                },
                label: {
                    Text("Check ax permissions")
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
