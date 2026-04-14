import Foundation
import StoreKit
import ComposableArchitecture

// MARK: - Product IDs

enum AstaraProduct: String, CaseIterable, Sendable {
    case monthlyPremium = "com.getastara.app.premium.monthly"
    case yearlyPremium  = "com.getastara.app.premium.yearly"

    var isYearly: Bool { self == .yearlyPremium }
}

// MARK: - Subscription Status

enum SubscriptionStatus: Equatable, Sendable {
    case free
    case premium(expiresAt: Date)
    case unknown
}

// MARK: - Service

@DependencyClient
struct SubscriptionService {
    var status: @Sendable () async -> SubscriptionStatus = { .free }
    var purchase: @Sendable (_ product: AstaraProduct) async throws -> SubscriptionStatus
    var restore: @Sendable () async throws -> SubscriptionStatus
}

extension SubscriptionService: DependencyKey {
    static let liveValue = SubscriptionService(
        status: {
            for await result in Transaction.currentEntitlements {
                guard case .verified(let tx) = result else { continue }
                if AstaraProduct(rawValue: tx.productID) != nil {
                    if let expiry = tx.expirationDate, expiry > Date() {
                        return .premium(expiresAt: expiry)
                    }
                }
            }
            return .free
        },

        purchase: { product in
            let storeProducts = try await Product.products(for: [product.rawValue])
            guard let storeProduct = storeProducts.first else {
                throw SubscriptionError.productNotFound
            }

            let result = try await storeProduct.purchase()

            switch result {
            case .success(let verification):
                guard case .verified(let tx) = verification else {
                    throw SubscriptionError.verificationFailed
                }
                await tx.finish()
                let expiry = tx.expirationDate ?? Date().addingTimeInterval(30 * 86400)
                return .premium(expiresAt: expiry)

            case .userCancelled:
                return .free

            case .pending:
                return .free

            @unknown default:
                return .free
            }
        },

        restore: {
            try await AppStore.sync()
            for await result in Transaction.currentEntitlements {
                guard case .verified(let tx) = result else { continue }
                if AstaraProduct(rawValue: tx.productID) != nil {
                    if let expiry = tx.expirationDate, expiry > Date() {
                        return .premium(expiresAt: expiry)
                    }
                }
            }
            return .free
        }
    )

    static let previewValue = SubscriptionService(
        status: { .free },
        purchase: { _ in .premium(expiresAt: Date().addingTimeInterval(30 * 86400)) },
        restore: { .free }
    )
}

extension DependencyValues {
    var subscriptionService: SubscriptionService {
        get { self[SubscriptionService.self] }
        set { self[SubscriptionService.self] = newValue }
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case productNotFound
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .productNotFound: return "Product not found in App Store."
        case .verificationFailed: return "Purchase verification failed."
        }
    }
}
