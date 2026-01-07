import Foundation

// MARK: - RevenueCat Stub
// This file provides stub types that mirror RevenueCat's API.
// When RevenueCat SDK is installed via SPM, these types are not used.
// Delete this file once you confirm the SDK is properly installed.

#if !canImport(RevenueCat)

// MARK: - Purchases

enum Purchases {
    static var logLevel: LogLevel = .debug
    static var shared: PurchasesInstance { PurchasesInstance.shared }

    static func configure(withAPIKey apiKey: String) {
        print("[RevenueCat Stub] Configure called - add real SDK for production")
    }

    enum LogLevel {
        case debug
        case info
        case warn
        case error
    }
}

class PurchasesInstance {
    static let shared = PurchasesInstance()
    weak var delegate: PurchasesDelegate?

    func customerInfo() async throws -> CustomerInfo {
        return CustomerInfo()
    }

    func offerings() async throws -> Offerings {
        return Offerings()
    }

    func purchase(package: Package) async throws -> PurchaseResult {
        // Simulate purchase for testing
        return PurchaseResult(customerInfo: CustomerInfo(isPremium: true), userCancelled: false)
    }

    func restorePurchases() async throws -> CustomerInfo {
        return CustomerInfo()
    }
}

// MARK: - CustomerInfo

class CustomerInfo {
    let entitlements: Entitlements
    private let isPremium: Bool

    init(isPremium: Bool = false) {
        self.isPremium = isPremium
        self.entitlements = Entitlements(isPremium: isPremium)
    }
}

// MARK: - Entitlements

class Entitlements {
    private let isPremium: Bool

    init(isPremium: Bool) {
        self.isPremium = isPremium
    }

    subscript(key: String) -> EntitlementInfo? {
        return EntitlementInfo(isActive: isPremium)
    }
}

class EntitlementInfo {
    let isActive: Bool

    init(isActive: Bool) {
        self.isActive = isActive
    }
}

// MARK: - Offerings

class Offerings {
    var current: Offering? {
        return Offering()
    }
}

class Offering {
    var availablePackages: [Package] {
        return [monthlyPackage, annualPackage].compactMap { $0 }
    }

    var monthly: Package? {
        return Package(
            identifier: "speak_premium_monthly",
            packageType: .monthly,
            localizedPriceString: "$9.99",
            product: StoreProduct(
                pricePerMonth: 9.99,
                introDiscount: nil
            )
        )
    }

    var annual: Package? {
        return Package(
            identifier: "speak_premium_yearly",
            packageType: .annual,
            localizedPriceString: "$59.99",
            product: StoreProduct(
                pricePerMonth: 4.99,
                introDiscount: IntroductoryDiscount(
                    period: SubscriptionPeriod(value: 7, unit: .day)
                )
            )
        )
    }

    private var monthlyPackage: Package? { monthly }
    private var annualPackage: Package? { annual }
}

// MARK: - Package

class Package {
    let identifier: String
    let packageType: PackageType
    let localizedPriceString: String
    let storeProduct: StoreProduct

    init(identifier: String, packageType: PackageType, localizedPriceString: String, product: StoreProduct) {
        self.identifier = identifier
        self.packageType = packageType
        self.localizedPriceString = localizedPriceString
        self.storeProduct = product
    }

    /// Formatted price string (e.g., "$4.99/month")
    var pricePerPeriod: String {
        let price = localizedPriceString
        let period = packageType.periodString
        return "\(price)/\(period)"
    }

    /// Calculate savings compared to monthly
    func savingsPercentage(comparedTo monthly: Package?) -> Int? {
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

enum PackageType {
    case monthly
    case annual
    case weekly
    case lifetime
    case twoMonth
    case threeMonth
    case sixMonth
    case custom

    var periodString: String {
        switch self {
        case .monthly: return "month"
        case .annual: return "year"
        case .weekly: return "week"
        case .lifetime: return "lifetime"
        case .twoMonth: return "2 months"
        case .threeMonth: return "3 months"
        case .sixMonth: return "6 months"
        case .custom: return ""
        }
    }
}

// MARK: - StoreProduct

class StoreProduct {
    let pricePerMonth: NSDecimalNumber?
    let introductoryDiscount: IntroductoryDiscount?

    init(pricePerMonth: Double?, introDiscount: IntroductoryDiscount?) {
        self.pricePerMonth = pricePerMonth.map { NSDecimalNumber(value: $0) }
        self.introductoryDiscount = introDiscount
    }
}

// MARK: - Introductory Discount

class IntroductoryDiscount {
    let subscriptionPeriod: SubscriptionPeriod

    init(period: SubscriptionPeriod) {
        self.subscriptionPeriod = period
    }
}

class SubscriptionPeriod {
    let value: Int
    let unit: Unit

    init(value: Int, unit: Unit) {
        self.value = value
        self.unit = unit
    }

    enum Unit {
        case day
        case week
        case month
        case year
    }
}

// MARK: - Purchase Result

struct PurchaseResult {
    let customerInfo: CustomerInfo
    let userCancelled: Bool
}

// MARK: - Delegate

protocol PurchasesDelegate: AnyObject {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo)
}

#endif
