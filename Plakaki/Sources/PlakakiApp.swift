import SwiftUI

@main
struct PlakakiApp: App {
    let appEnumerator = AppEnumerator()

    var body: some Scene {
        WindowGroup {
            ContentView(appEnumerator: appEnumerator)
        }
        MenuBarExtra {
            MenuBarContent(appEnumerator: appEnumerator)
        } label: {
            MenuBarLabel()
        }
    }
}
