import SwiftUI
import SwiftData

@main
struct JotMoneyApp: App {
    private let container: ModelContainer

    init() {
        container = Persistence.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
