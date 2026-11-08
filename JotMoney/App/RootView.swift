import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]
    @State private var hasCompletedOnboarding = AppPreferences.onboardingComplete

    var body: some View {
        Group {
            if !hasCompletedOnboarding || accounts.isEmpty {
                OnboardingView {
                    hasCompletedOnboarding = true
                    AppPreferences.onboardingComplete = true
                }
            } else {
                MainTabView()
            }
        }
        .screenBackground()
        .task {
            EntryService.shared.seedIfNeeded(context: context)
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-seedDemo") {
                DemoSeed.seedIfNeeded(context: context)
                hasCompletedOnboarding = true
            }
            #endif
            EntryService.shared.materializeInstallments(context: context)
            EntryService.shared.materializeRecurring(context: context)
        }
    }
}

struct MainTabView: View {
    @State private var selection: Tab = MainTabView.initialTab

    enum Tab: Hashable {
        case home
        case ledger
        case insights
    }

    static var initialTab: Tab {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"), arguments.count > index + 1 {
            switch arguments[index + 1] {
            case "ledger": return .ledger
            case "insights": return .insights
            default: return .home
            }
        }
        #endif
        return .home
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            LedgerView()
                .tabItem { Label("Ledger", systemImage: "list.bullet.rectangle") }
                .tag(Tab.ledger)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(Tab.insights)
        }
        .tint(Theme.mint)
    }
}
