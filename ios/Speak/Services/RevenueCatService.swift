import Foundation
#if canImport(RevenueCat)
import RevenueCat
#endif

/// RevenueCat integration wrapper
/// Handles configuration, entitlement checks, and purchases
final class RevenueCatService: ObservableObject {
    static let shared = RevenueCatService()

    // MARK: - Configuration

    /// Your RevenueCat public API key (replace with your actual key)
    private let apiKey = "your_revenuecat_api_key_here"

    // Product identifiers (must match App Store Connect)
    static let monthlyProductID = "com.rhyshdavies.speak.premium.monthly"
    static let yearlyProductID = "com.rhyshdavies.speak.premium.annual"

    // Entitlement identifier
    static let premiumEntitlement = "premium"

    // MARK: - Published State

    @Published private(set) var isConfigured = false
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var offerings: Offerings?
    @Published private(set) var isPremium = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Configuration

    /// Configure RevenueCat - call this once at app launch
    func configure() {
        guard !isConfigured else { return }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true

        // Set up listener for customer info updates
        Purchases.shared.delegate = self

        // Fetch initial data
        Task {
            await refreshCustomerInfo()
            await fetchOfferings()
        }
    }

    // MARK: - Customer Info

    /// Refresh customer info and update premium status
    @MainActor
    func refreshCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            self.customerInfo = info
            self.isPremium = info.entitlements[Self.premiumEntitlement]?.isActive == true
        } catch {
            print("[RevenueCat] Failed to fetch customer info: \(error)")
        }
    }

    /// Check if user has active premium entitlement
    var hasPremiumAccess: Bool {
        customerInfo?.entitlements[Self.premiumEntitlement]?.isActive == true
    }

    // MARK: - Offerings

    /// Fetch available offerings (products)
    @MainActor
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
        } catch {
            print("[RevenueCat] Failed to fetch offerings: \(error)")
        }
    }

    /// Get the default offering's packages
    var availablePackages: [Package] {
        offerings?.current?.availablePackages ?? []
    }

    /// Get monthly package from current offering
    var monthlyPackage: Package? {
        offerings?.current?.monthly
    }

    /// Get annual package from current offering
    var annualPackage: Package? {
        offerings?.current?.annual
    }

    // MARK: - Purchases

    /// Purchase a package
    @MainActor
    func purchase(_ package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)

        // Update customer info after purchase
        self.customerInfo = result.customerInfo
        self.isPremium = result.customerInfo.entitlements[Self.premiumEntitlement]?.isActive == true

        // Return true if transaction completed (not cancelled)
        return !result.userCancelled
    }

    /// Restore previous purchases
    @MainActor
    func restorePurchases() async throws {
        let info = try await Purchases.shared.restorePurchases()
        self.customerInfo = info
        self.isPremium = info.entitlements[Self.premiumEntitlement]?.isActive == true
    }
}

// MARK: - PurchasesDelegate

#if canImport(RevenueCat)
extension RevenueCatService: RevenueCat.PurchasesDelegate {
    func purchases(_ purchases: RevenueCat.Purchases, receivedUpdated customerInfo: RevenueCat.CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.isPremium = customerInfo.entitlements[Self.premiumEntitlement]?.isActive == true
        }
    }
}

// MARK: - Helpers

extension RevenueCat.Package {
    /// Formatted price string (e.g., "$4.99/month")
    var pricePerPeriod: String {
        let price = localizedPriceString
        let period = packageType.periodString
        return "\(price)/\(period)"
    }

    /// Calculate savings compared to monthly
    func savingsPercentage(comparedTo monthly: RevenueCat.Package?) -> Int? {
        guard let monthly = monthly,
              let monthlyPrice = monthly.storeProduct.pricePerMonth?.doubleValue,
              let thisPrice = storeProduct.pricePerMonth?.doubleValue,
              monthlyPrice > 0 else {
            return nil
        }

        let savings = 1.0 - (thisPrice / monthlyPrice)
        return Int(savings * 100)
    }
}

extension RevenueCat.PackageType {
    var periodString: String {
        switch self {
        case .monthly: return "month"
        case .annual: return "year"
        case .weekly: return "week"
        case .lifetime: return "lifetime"
        case .twoMonth: return "2 months"
        case .threeMonth: return "3 months"
        case .sixMonth: return "6 months"
        default: return ""
        }
    }
}
#else
extension RevenueCatService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.isPremium = customerInfo.entitlements[Self.premiumEntitlement]?.isActive == true
        }
    }
}
#endif
