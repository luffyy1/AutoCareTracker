import SwiftUI
import SwiftData

/// Вход -> онбординг (если нет машины) -> дашборд
struct ContentView: View {
    @Environment(AuthManager.self) private var auth
    @Query private var cars: [Car]

    var body: some View {
        if !auth.isLoggedIn {
            LoginView()
        } else if let car = cars.first {
            MainTabView(car: car)
        } else {
            OnboardingView()
        }
    }
}
