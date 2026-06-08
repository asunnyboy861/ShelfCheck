import Foundation
import StoreKit

@Observable
final class PurchaseManager {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isProUser = false
    var isLoading = true

    static let monthlyID = "com.zzoutuo.ShelfCheck.monthly"
    static let yearlyID = "com.zzoutuo.ShelfCheck.yearly"
    static let lifetimeID = "com.zzoutuo.ShelfCheck.lifetime"

    private var transactionListener: Task<Void, Never>?
    private(set) var freeBookLimit = 50

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var lifetimeProduct: Product? { products.first { $0.id == Self.lifetimeID } }

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.monthlyID, Self.yearlyID, Self.lifetimeID])
            await updatePurchasedStatus()
        } catch {
            isLoading = false
        }
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await updatePurchasedStatus()
                    await transaction.finish()
                    return true
                case .unverified:
                    return false
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
        } catch {}
    }

    func canAddBook(currentCount: Int) -> Bool {
        return isProUser || currentCount < freeBookLimit
    }

    var freeBookLimitReached: Bool {
        return !isProUser
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                switch result {
                case .verified(let transaction):
                    await self.updatePurchasedStatus()
                    await transaction.finish()
                case .unverified:
                    break
                }
            }
        }
    }

    private func updatePurchasedStatus() async {
        var purchasedIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                purchasedIDs.insert(transaction.productID)
            case .unverified:
                break
            }
        }

        purchasedProductIDs = purchasedIDs
        isProUser = !purchasedIDs.isEmpty
        isLoading = false
    }
}
