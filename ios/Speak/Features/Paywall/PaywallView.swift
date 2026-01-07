import SwiftUI
#if canImport(RevenueCat)
import RevenueCat
#endif

/// Paywall screen shown when user hits a premium feature limit
struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var revenueCat = RevenueCatService.shared

    let trigger: PaywallTrigger?

    @State private var selectedPlan: PlanType = .yearly
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false

    enum PlanType {
        case monthly
        case yearly
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                    }
                    .padding(.top, Theme.Spacing.md)

                    // Hero section
                    heroSection

                    // Benefits list
                    benefitsSection

                    // Pricing cards
                    pricingSection

                    // CTA Button
                    ctaSection

                    // Restore & Legal
                    footerSection
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }

            // Loading overlay
            if isProcessing || subscriptionManager.isLoading {
                loadingOverlay
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Something went wrong. Please try again.")
        }
        .onAppear {
            Task {
                await revenueCat.fetchOfferings()
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary)

            Text("Unlock Faster Fluency")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Practice more. Get detailed feedback.\nSpeak with confidence.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            BenefitRow(icon: "infinity", text: "Unlimited daily practice")
            BenefitRow(icon: "text.bubble", text: "Detailed corrections & explanations")
            BenefitRow(icon: "chart.bar.fill", text: "Advanced scenarios (B2-C2)")
            BenefitRow(icon: "clock.arrow.circlepath", text: "Full review history")
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Yearly plan (recommended)
            PricingCard(
                title: "Yearly",
                price: yearlyPriceString,
                period: "per year",
                savings: savingsText,
                isSelected: selectedPlan == .yearly,
                isRecommended: true
            ) {
                HapticManager.selection()
                selectedPlan = .yearly
            }

            // Monthly plan
            PricingCard(
                title: "Monthly",
                price: monthlyPriceString,
                period: "per month",
                savings: nil,
                isSelected: selectedPlan == .monthly,
                isRecommended: false
            ) {
                HapticManager.selection()
                selectedPlan = .monthly
            }
        }
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            PrimaryButton(ctaButtonText, icon: "crown.fill") {
                Task {
                    await purchase()
                }
            }
            .disabled(isProcessing)

            if let trialText = trialInfoText {
                Text(trialText)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Restore purchases
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.primary)
            }
            .disabled(isProcessing)

            // Legal links
            HStack(spacing: Theme.Spacing.lg) {
                Link("Terms of Use", destination: URL(string: "https://speak.app/terms")!)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textTertiary)

                Link("Privacy Policy", destination: URL(string: "https://speak.app/privacy")!)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
            }

            // Subscription terms
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. You can manage and cancel your subscriptions in your App Store account settings.")
                .font(.system(size: 10))
                .foregroundColor(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Theme.Colors.primary)

                Text("Processing...")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .padding(Theme.Spacing.xl)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        }
    }

    // MARK: - Price Helpers

    private var monthlyPriceString: String {
        revenueCat.monthlyPackage?.localizedPriceString ?? "$4.99"
    }

    private var yearlyPriceString: String {
        revenueCat.annualPackage?.localizedPriceString ?? "$39.99"
    }

    private var savingsText: String? {
        guard let annual = revenueCat.annualPackage,
              let monthly = revenueCat.monthlyPackage,
              let savings = annual.savingsPercentage(comparedTo: monthly),
              savings > 0 else {
            return "Save 33%"  // Default fallback
        }
        return "Save \(savings)%"
    }

    private var ctaButtonText: String {
        if let package = selectedPlan == .yearly ? revenueCat.annualPackage : revenueCat.monthlyPackage,
           package.storeProduct.introductoryDiscount != nil {
            return "Start Free Trial"
        }
        return "Subscribe Now"
    }

    private var trialInfoText: String? {
        let package = selectedPlan == .yearly ? revenueCat.annualPackage : revenueCat.monthlyPackage
        guard let intro = package?.storeProduct.introductoryDiscount else {
            return nil
        }

        let days = intro.subscriptionPeriod.value
        let unit = intro.subscriptionPeriod.unit == .day ? "day" : "week"
        return "\(days)-\(unit) free trial, then \(package?.localizedPriceString ?? "") per \(selectedPlan == .yearly ? "year" : "month")"
    }

    // MARK: - Actions

    private func purchase() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let success: Bool
            if selectedPlan == .yearly {
                success = try await subscriptionManager.purchaseYearly()
            } else {
                success = try await subscriptionManager.purchaseMonthly()
            }

            if success {
                HapticManager.success()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }

    private func restorePurchases() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await subscriptionManager.restorePurchases()

            if subscriptionManager.tier == .premium {
                HapticManager.success()
                dismiss()
            } else {
                errorMessage = "No active subscription found for this account."
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let savings: String?
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(title)
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.textPrimary)

                        if isRecommended {
                            Text("BEST VALUE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, Theme.Spacing.sm)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.primary)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: Theme.Spacing.sm) {
                        Text(price)
                            .font(Theme.Typography.title2)
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text(period)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }

                    if let savings = savings {
                        Text(savings)
                            .font(Theme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.success)
                    }
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: Theme.Shadows.small.color,
                radius: Theme.Shadows.small.radius,
                y: Theme.Shadows.small.y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 28)

            Text(text)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}

#Preview {
    PaywallView(trigger: .practiceLimit)
        .environmentObject(SubscriptionManager.shared)
}
