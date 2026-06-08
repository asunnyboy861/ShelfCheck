import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("isContinuousScan") private var isContinuousScan = false
    @AppStorage("defaultShelfLocation") private var defaultShelfLocation = ""
    @State private var purchaseManager = PurchaseManager()
    @State private var showPaywall = false
    @Query private var books: [Book]

    var body: some View {
        NavigationStack {
            Form {
                proSection
                scanSection
                librarySection
                aboutSection
                legalSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView(purchaseManager: purchaseManager)
            }
        }
    }

    private var proSection: some View {
        Group {
            if purchaseManager.isProUser {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("ShelfCheck Pro")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(Color.shelfGreen)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown")
                            .foregroundStyle(.yellow)
                        Text("Upgrade to Pro")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.shelfGreen)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !purchaseManager.isProUser {
                LabeledContent("Free Plan", value: "\(books.count)/\(purchaseManager.freeBookLimit) books")
            }
        }
    }

    private var scanSection: some View {
        Section("Scanning") {
            Toggle("Continuous Scan Mode", isOn: $isContinuousScan)
        }
    }

    private var librarySection: some View {
        Section("Library") {
            TextField("Default Shelf Location", text: $defaultShelfLocation)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/ShelfCheck/privacy.html")!)
            Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/ShelfCheck/terms.html")!)
            Link("Support", destination: URL(string: "https://asunnyboy861.github.io/ShelfCheck/support.html")!)
            if purchaseManager.isProUser {
                Button("Restore Purchases") {
                    Task { await purchaseManager.restorePurchases() }
                }
            }
        }
    }
}
