import SwiftUI
import SwiftData

@main
struct ShelfCheckApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: Book.self)
    }
}
