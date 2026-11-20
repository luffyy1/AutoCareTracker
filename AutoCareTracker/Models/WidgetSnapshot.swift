import Foundation

/// Короткая сводка для виджета. Приложение сохраняет её в общую
/// папку (App Group), а виджет оттуда читает.
/// ВАЖНО: такой же файл лежит в папке AutoCareWidget. Меняешь один, меняй и второй.
struct WidgetSnapshot: Codable {
    struct Part: Codable {
        var name: String
        var percent: Int        // остаток ресурса, 0–100
        var kmLeft: Int
        var overdueKm: Int
        var dueDate: Date?      // расчётная дата замены, nil = прогноза нет
    }

    var carName: String
    var mileage: Int
    var parts: [Part]           // самые срочные идут первыми
    var tireSwitch: String?     // "winter" / "summer", если пора менять шины
    var updatedAt: Date

    static let appGroup = "group.mmm.AutoCareTracker"
    private static let key = "widget.snapshot"

    static func load() -> WidgetSnapshot? {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: WidgetSnapshot?) {
        let defaults = UserDefaults(suiteName: appGroup)
        if let snapshot, let data = try? JSONEncoder().encode(snapshot) {
            defaults?.set(data, forKey: key)
        } else {
            defaults?.removeObject(forKey: key)
        }
    }
}
