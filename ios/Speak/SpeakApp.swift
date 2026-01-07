import SwiftUI

/// Paywall trigger context for analytics
enum PaywallTrigger {
    case practiceLimit
    case feedbackLocked
    case levelLocked
    case reviewLimitReached
}

@main
struct SpeakApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    init() {
        // Configure RevenueCat at app launch
        SubscriptionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscriptionManager)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedLevel: CEFRLevel = .a1
    @State private var selectedLanguage: Language = .spanish
    @State private var showingScenarios = false
    @State private var showingPaywall = false
    @State private var paywallTrigger: PaywallTrigger?

    var body: some View {
        NavigationStack {
            HomeView(
                selectedLevel: $selectedLevel,
                selectedLanguage: $selectedLanguage,
                showingScenarios: $showingScenarios,
                showPaywall: { trigger in
                    paywallTrigger = trigger
                    showingPaywall = true
                }
            )
            .navigationDestination(isPresented: $showingScenarios) {
                ScenarioListView(
                    selectedLevel: selectedLevel,
                    selectedLanguage: selectedLanguage,
                    showPaywall: { trigger in
                        paywallTrigger = trigger
                        showingPaywall = true
                    }
                )
            }
        }
        .preferredColorScheme(.light) // Warm modernity theme uses light mode
        .sheet(isPresented: $showingPaywall) {
            PaywallView(trigger: paywallTrigger)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SubscriptionManager.shared)
}
