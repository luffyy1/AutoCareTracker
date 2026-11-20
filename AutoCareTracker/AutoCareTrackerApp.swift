import SwiftUI
import SwiftData

@main
struct AutoCareTrackerApp: App {
    @State private var auth = AuthManager()
    @AppStorage(L.key, store: L.store) private var language = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
                // Выбранный язык: меняет переводы и пересобирает экраны
                .environment(\.locale, L.locale(for: language))
                .id(language)
                .preferredColorScheme(.dark)
                .tint(.brand)
        }
        .modelContainer(for: [Car.self, Component.self, OdometerEntry.self])
    }
}
