import SwiftUI
import SwiftData

/// Нижняя панель: Гараж и Ещё.
/// Здесь же ведётся журнал пробега и обновляются уведомления.
struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \OdometerEntry.date) private var entries: [OdometerEntry]
    @State private var tires = TireAdvisor()
    let car: Car

    private var kmPerDay: Double? { Forecast.kmPerDay(entries) }

    /// Меняется, когда меняется пробег или любой расходник
    private var signature: [Int] {
        [car.currentMileage, car.components.count]
            + car.components.flatMap { [$0.lastServiceKm, $0.intervalKm] }
    }

    var body: some View {
        TabView {
            DashboardView(car: car, kmPerDay: kmPerDay, tires: tires)
                .tabItem { Label("Garage", systemImage: "car.fill") }
            MoreView(car: car)
                .tabItem { Label("More", systemImage: "square.grid.2x2.fill") }
        }
        .task {
            logMileage()
            await NotificationManager.requestPermission()
            await tires.refresh()
            await reschedule()
        }
        .onChange(of: signature) {
            logMileage()
            Task { await reschedule() }
        }
        .onChange(of: entries.count) {
            Task { await reschedule() }
        }
        .onChange(of: tires.needsSwitch) {
            Task { await reschedule() }
        }
    }

    /// Запоминает пробег с датой: по этим записям считается пробег в день
    private func logMileage() {
        let km = car.currentMileage
        if let last = entries.last {
            if last.km == km { return }
            // В один и тот же день просто поправляем запись
            if Calendar.current.isDateInToday(last.date) {
                last.km = km
                return
            }
        }
        context.insert(OdometerEntry(km: km))
    }

    private func reschedule() async {
        // Сначала обновляем виджет, потом уведомления
        WidgetSync.update(car: car,
                          kmPerDay: Forecast.kmPerDay(entries),
                          tireSwitch: tires.needsSwitch ? tires.recommended : nil)
        await NotificationManager.reschedule(
            for: car,
            kmPerDay: Forecast.kmPerDay(entries),
            tireSwitch: tires.needsSwitch ? tires.recommended : nil)
    }
}
