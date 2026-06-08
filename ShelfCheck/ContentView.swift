import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanTabView()
                .tabItem {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
                .tag(0)
            LibraryView()
                .tabItem {
                    Label("My Shelf", systemImage: "books.vertical")
                }
                .tag(1)
            AddBookView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }
                .tag(2)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .tint(Color.shelfGreen)
    }
}
