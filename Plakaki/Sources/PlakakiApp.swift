import SwiftUI

@main
struct PlakakiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        MenuBarExtra {
            MenuBarContent()
        } label: {
            MenuBarLabel()
        }
    }
}
