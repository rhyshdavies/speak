import SwiftUI

@main
struct SpeakApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var selectedLevel: CEFRLevel = .a1
    @State private var selectedMode: ConversationMode = .beginner
    @State private var showingScenarios = false

    var body: some View {
        NavigationStack {
            HomeView(
                selectedLevel: $selectedLevel,
                selectedMode: $selectedMode,
                showingScenarios: $showingScenarios
            )
            .navigationDestination(isPresented: $showingScenarios) {
                ScenarioListView(
                    selectedLevel: selectedLevel,
                    selectedMode: selectedMode
                )
            }
        }
        .preferredColorScheme(.dark) // Matrix cyberpunk theme
    }
}

#Preview {
    RootView()
}
