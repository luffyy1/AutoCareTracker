import Foundation

/// Прогноз: через сколько дней деталь выработает ресурс
enum Forecast {

    /// Средний пробег в день по истории одометра.
    /// Нужны минимум две записи с разницей хотя бы в сутки.
    static func kmPerDay(_ entries: [OdometerEntry]) -> Double? {
        let sorted = entries.sorted { $0.date < $1.date }
        // Берём последние 90 дней, если там хватает записей
        let cutoff = Date().addingTimeInterval(-90 * 86_400)
        let recent = sorted.filter { $0.date >= cutoff }
        let used = recent.count >= 2 ? recent : sorted

        guard let first = used.first, let last = used.last else { return nil }
        let days = last.date.timeIntervalSince(first.date) / 86_400
        let km = Double(last.km - first.km)
        guard days >= 1, km > 0 else { return nil }
        return km / days
    }

    /// Сколько дней осталось до замены. nil = данных для прогноза пока нет
    static func daysLeft(for c: Component, mileage: Int, kmPerDay: Double?) -> Int? {
        guard let kmPerDay, kmPerDay > 0 else { return nil }
        let kmLeft = c.intervalKm - (mileage - c.lastServiceKm)
        guard kmLeft > 0 else { return 0 }
        return Int((Double(kmLeft) / kmPerDay).rounded(.up))
    }

    static func dueDate(daysLeft: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: daysLeft, to: Date()) ?? Date()
    }
}
