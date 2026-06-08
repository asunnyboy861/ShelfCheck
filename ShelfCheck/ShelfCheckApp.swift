import SwiftUI
import SwiftData

@main
struct ShelfCheckApp: App {
    @State private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(purchaseManager)
        }
        .modelContainer(for: Book.self)
    }
}
