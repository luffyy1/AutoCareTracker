import Foundation
import WidgetKit

/// Передаёт свежие данные виджету на экране «Домой»
@MainActor
enum WidgetSync {

    static func update(car: Car, kmPerDay: Double?, tireSwitch: TireKind?) {
        var parts: [WidgetSnapshot.Part] = []
        for c in car.components {
            let used = max(0, car.currentMileage - c.lastServiceKm)
            let days = Forecast.daysLeft(for: c, mileage: car.currentMileage, kmPerDay: kmPerDay)
            parts.append(WidgetSnapshot.Part(
                name: L.name(c.name),
                percent: WearEngine.remainingPercent(for: c, currentMileage: car.currentMileage),
                kmLeft: max(0, c.intervalKm - used),
                overdueKm: max(0, used - c.intervalKm),
                dueDate: days.map { Forecast.dueDate(daysLeft: $0) }))
        }
        // Самая срочная деталь первой: просроченные, затем с наименьшим остатком км
        parts.sort { ($0.kmLeft - $0.overdueKm) < ($1.kmLeft - $1.overdueKm) }

        WidgetSnapshot.save(WidgetSnapshot(carName: car.name,
                                           mileage: car.currentMileage,
                                           parts: parts,
                                           tireSwitch: tireSwitch?.rawValue,
                                           updatedAt: Date()))
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// При выходе из аккаунта виджет очищается
    static func clear() {
        WidgetSnapshot.save(nil)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
