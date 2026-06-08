import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let purchaseManager: PurchaseManager
    @State private var selectedPlan: PlanType = .yearly
    @State private var isPurchasing = false

    enum PlanType: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
        case lifetime = "Lifetime"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featureComparison
                    planSelector
                    subscribeButton
                    legalLinks
                    restoreButton
                }
                .padding()
            }
            .background(Color.shelfBackground)
            .navigationTitle("ShelfCheck Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.shelfGreen)

            Text("Unlock Your Full Library")
                .font(.title2.bold())

            Text("Remove the 50-book limit and unlock all Pro features")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var featureComparison: some View {
        VStack(spacing: 12) {
            featureRow(icon: "barcode.viewfinder", title: "Scan & Check", free: "Unlimited", pro: "Unlimited")
            featureRow(icon: "books.vertical", title: "Book Shelf", free: "50 books", pro: "Unlimited")
            featureRow(icon: "arrow.triangle.2.circlepath", title: "Continuous Scan", free: "—", pro: "✓")
            featureRow(icon: "person.crop.circle.badge.plus", title: "Lending Tracker", free: "—", pro: "✓")
            featureRow(icon: "tag.fill", title: "Custom Tags", free: "—", pro: "✓")
            featureRow(icon: "square.and.arrow.up", title: "CSV Export", free: "—", pro: "✓")
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private func featureRow(icon: String, title: String, free: String, pro: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(Color.shelfGreen)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(free)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60)
            Text(pro)
                .font(.caption.bold())
                .foregroundStyle(Color.shelfGreen)
                .frame(width: 60)
        }
    }

    private var planSelector: some View {
        VStack(spacing: 10) {
            ForEach(PlanType.allCases, id: \.self) { plan in
                planCard(plan)
            }
        }
    }

    private func planCard(_ plan: PlanType) -> some View {
        let isSelected = selectedPlan == plan
        let product = productForPlan(plan)

        return Button {
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.rawValue)
                            .font(.subheadline.bold())
                        if plan == .yearly {
                            Text("Best Value")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.shelfGreen)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product?.displayPrice ?? priceString(for: plan))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if plan == .monthly {
                        Text("7-day free trial")
                            .font(.caption2)
                            .foregroundStyle(Color.shelfGreen)
                    } else if plan == .yearly {
                        Text("7-day free trial, save 58%")
                            .font(.caption2)
                            .foregroundStyle(Color.shelfGreen)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.shelfGreen : .gray)
            }
            .padding()
            .background(isSelected ? Color.shelfGreen.opacity(0.08) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.shelfGreen : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var subscribeButton: some View {
        Button {
            purchaseSelectedPlan()
        } label: {
            if isPurchasing {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            } else {
                Text("Start 7-Day Free Trial")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
        }
        .background(Color.shelfGreen)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .disabled(isPurchasing)
    }

    private var legalLinks: some View {
        VStack(spacing: 4) {
            Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/ShelfCheck/privacy.html")!)
                    .font(.caption2)
                    .foregroundStyle(Color.shelfGreen)
                Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/ShelfCheck/terms.html")!)
                    .font(.caption2)
                    .foregroundStyle(Color.shelfGreen)
            }
            .padding(.top, 2)
        }
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await purchaseManager.restorePurchases() }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func productForPlan(_ plan: PlanType) -> Product? {
        switch plan {
        case .monthly: purchaseManager.monthlyProduct
        case .yearly: purchaseManager.yearlyProduct
        case .lifetime: purchaseManager.lifetimeProduct
        }
    }

    private func priceString(for plan: PlanType) -> String {
        switch plan {
        case .monthly: return "$1.99/month"
        case .yearly: return "$9.99/year"
        case .lifetime: return "$19.99 once"
        }
    }

    private func purchaseSelectedPlan() {
        guard let product = productForPlan(selectedPlan) else { return }
        isPurchasing = true
        Task {
            let success = await purchaseManager.purchase(product)
            await MainActor.run {
                isPurchasing = false
                if success { dismiss() }
            }
        }
    }
}
