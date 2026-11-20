import WidgetKit
import SwiftUI

// MARK: - Язык

/// Язык, выбранный в приложении (виджет читает его из общей группы)
enum WL {
    static var code: String {
        UserDefaults(suiteName: WidgetSnapshot.appGroup)?.string(forKey: "app.language") ?? "system"
    }

    static var locale: Locale {
        code == "system" ? Locale.current : Locale(identifier: code)
    }

    static var bundle: Bundle {
        let code = self.code
        if code == "system" { return .main }
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        if code == "en" { return Bundle(path: NSTemporaryDirectory()) ?? .main }
        return .main
    }

    static func text(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: bundle, locale: locale)
    }
}

// MARK: - Данные

struct CareEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CareEntry {
        CareEntry(date: Date(), snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (CareEntry) -> Void) {
        // В галерее виджетов показываем пример, если своих данных ещё нет
        let snapshot = WidgetSnapshot.load() ?? (context.isPreview ? .sample : nil)
        completion(CareEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CareEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Запись на сейчас и на каждую полночь недели вперёд:
        // счётчик дней уменьшается сам, даже если приложение не открывали
        var entries = [CareEntry(date: Date(), snapshot: snapshot)]
        for offset in 1...7 {
            if let day = calendar.date(byAdding: .day, value: offset, to: today) {
                entries.append(CareEntry(date: day, snapshot: snapshot))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

extension WidgetSnapshot {
    static let sample = WidgetSnapshot(
        carName: "Toyota Camry",
        mileage: 182_400,
        parts: [
            Part(name: "Engine oil", percent: 18, kmLeft: 1_800, overdueKm: 0,
                 dueDate: Calendar.current.date(byAdding: .day, value: 23, to: Date())),
            Part(name: "Filters", percent: 55, kmLeft: 8_200, overdueKm: 0,
                 dueDate: Calendar.current.date(byAdding: .day, value: 96, to: Date())),
            Part(name: "Brake pads", percent: 85, kmLeft: 34_000, overdueKm: 0, dueDate: nil)
        ],
        tireSwitch: nil,
        updatedAt: Date())
}

extension WidgetSnapshot.Part {
    /// Тот же светофор, что и в приложении
    var color: Color {
        if overdueKm > 0 || percent < 20 { return .red }
        return percent < 80 ? .yellow : .green
    }

    /// Сколько дней осталось до замены, если есть прогноз
    func daysLeft(from now: Date) -> Int? {
        guard let dueDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: now),
                                           to: calendar.startOfDay(for: dueDate)).day ?? 0
        return max(0, days)
    }

    /// Крупная надпись: «23», «Now» или «72%»
    func bigText(from now: Date) -> String {
        if overdueKm > 0 { return WL.text("Now") }
        if let days = daysLeft(from: now) { return days == 0 ? WL.text("Now") : "\(days)" }
        return "\(percent)%"
    }

    /// Полная фраза: «23 days left», «replace today», «overdue by 500 km»
    func fullText(from now: Date) -> String {
        if overdueKm > 0 { return WL.text("overdue by \(overdueKm) km") }
        if let days = daysLeft(from: now) {
            return days == 0 ? WL.text("replace today") : WL.text("\(days) days left")
        }
        return WL.text("\(kmLeft) km left")
    }

    /// Подпись под крупной надписью. Если наверху уже стоит число дней,
    /// убираем его из фразы: «23 days left» превращается в «days left»
    func caption(from now: Date) -> String {
        let full = fullText(from: now)
        guard overdueKm == 0, let days = daysLeft(from: now), days > 0 else { return full }
        return String(full.drop(while: { $0.isNumber || $0.isWhitespace }))
    }

    /// Короткий текст для списка: «23 d» или «72%»
    func shortText(from now: Date) -> String {
        if overdueKm > 0 { return WL.text("Now") }
        if let days = daysLeft(from: now) {
            return days == 0 ? WL.text("Now") : WL.text("\(days) d")
        }
        return "\(percent)%"
    }
}

// MARK: - Вид

struct AutoCareWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CareEntry

    var body: some View {
        if let snapshot = entry.snapshot, let first = snapshot.parts.first {
            switch family {
            case .systemMedium:
                HStack(spacing: 16) {
                    MainPartView(part: first, now: entry.date, tireSwitch: snapshot.tireSwitch)
                    PartListView(parts: Array(snapshot.parts.dropFirst().prefix(3)),
                                 carName: snapshot.carName, now: entry.date)
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(first.name).font(.headline).lineLimit(1)
                    Text(first.fullText(from: entry.date))
                        .font(.subheadline).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                MainPartView(part: first, now: entry.date, tireSwitch: snapshot.tireSwitch)
            }
        } else {
            VStack(spacing: 6) {
                Image(systemName: "car.fill").font(.title2)
                Text("Open Auto Care Tracker to add your car")
                    .font(.caption).multilineTextAlignment(.center)
            }
        }
    }
}

/// Главная деталь: цветная точка, название, крупное число дней
struct MainPartView: View {
    let part: WidgetSnapshot.Part
    let now: Date
    let tireSwitch: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle().fill(part.color).frame(width: 10, height: 10)
                Text(part.name).font(.caption.bold()).lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(part.bigText(from: now))
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(part.color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(part.caption(from: now))
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            if let tireSwitch {
                Label(tireSwitch == "winter" ? WL.text("Time for winter tires")
                                             : WL.text("Time for summer tires"),
                      systemImage: tireSwitch == "winter" ? "snowflake" : "sun.max.fill")
                    .font(.caption2).foregroundStyle(.orange).lineLimit(1)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Список следующих деталей (для среднего виджета)
struct PartListView: View {
    let parts: [WidgetSnapshot.Part]
    let carName: String
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(carName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                HStack(spacing: 6) {
                    Circle().fill(part.color).frame(width: 8, height: 8)
                    Text(part.name).font(.caption).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(part.shortText(from: now)).font(.caption.bold())
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Виджет

struct AutoCareWidget: Widget {
    let kind: String = "AutoCareWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AutoCareWidgetEntryView(entry: entry)
                .environment(\.colorScheme, .dark)
                .environment(\.locale, WL.locale)
                .containerBackground(for: .widget) {
                    Color(red: 0.07, green: 0.07, blue: 0.12)
                }
        }
        .configurationDisplayName("Auto Care")
        .description("Days left until your next part replacement.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    AutoCareWidget()
} timeline: {
    CareEntry(date: .now, snapshot: .sample)
}
