import Foundation
import UserNotifications

/// Локальные уведомления: работают без интернета и без сервера
@MainActor
enum NotificationManager {
    private static let center = UNUserNotificationCenter.current()

    @discardableResult
    static func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Пересоздаёт все напоминания по текущему состоянию машины.
    /// kmPerDay: средний пробег в день (nil, если прогноза ещё нет).
    /// tireSwitch: на какие шины пора перейти (nil, если менять не надо).
    static func reschedule(for car: Car, kmPerDay: Double?, tireSwitch: TireKind?) async {
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }
        center.removeAllPendingNotificationRequests()

        // Раз в неделю просим обновить пробег: от него зависят все проценты
        var weekly = DateComponents()
        weekly.weekday = 1   // воскресенье
        weekly.hour = 10
        await add(id: "odometer-weekly",
                  title: L.text("Update your odometer"),
                  body: L.text("Keep wear percentages accurate: enter your current mileage."),
                  trigger: UNCalendarNotificationTrigger(dateMatching: weekly, repeats: true))

        for c in car.components {
            let name = L.name(c.name)
            let percent = WearEngine.remainingPercent(for: c, currentMileage: car.currentMileage)
            let wear = WearEngine.status(for: percent)

            if wear == .red {
                // Красная деталь: напоминаем через 1, 3 и 7 дней, пока не заменят
                for days in [1, 3, 7] {
                    await add(id: "\(c.name)-red-\(days)",
                              title: L.text("\(name): replace now"),
                              body: L.text("Only \(percent)% of its life is left. Time to replace it."),
                              trigger: dayTrigger(inDays: days))
                }
            } else if let days = Forecast.daysLeft(for: c, mileage: car.currentMileage, kmPerDay: kmPerDay) {
                // Есть прогноз: напоминаем за неделю и в расчётный день замены
                if days > 7 {
                    await add(id: "\(c.name)-week-before",
                              title: L.text("\(name): due in about a week"),
                              body: L.text("At your usual mileage it will need replacing in about 7 days."),
                              trigger: dayTrigger(inDays: days - 7))
                }
                if days >= 1 {
                    await add(id: "\(c.name)-due",
                              title: L.text("\(name): due today"),
                              body: L.text("By your usual mileage it has reached its limit. Update the odometer to check."),
                              trigger: dayTrigger(inDays: days))
                }
            } else if wear == .yellow {
                // Прогноза нет: простое напоминание через 3 дня
                await add(id: "\(c.name)-yellow-3",
                          title: L.text("\(name): plan a replacement"),
                          body: L.text("\(percent)% of its life is left."),
                          trigger: dayTrigger(inDays: 3))
            }
        }

        // Шины: если прогноз говорит менять, напоминаем завтра
        if let tireSwitch {
            await add(id: "tires-switch",
                      title: tireSwitch.timeForText,
                      body: tireSwitch == .winter
                        ? L.text("It is getting cold. Book a tire change before the first ice.")
                        : L.text("It is warm enough. Winter tires wear out fast on warm roads."),
                      trigger: dayTrigger(inDays: 1))
        }

        // Шины по календарю: работает каждый год даже без интернета
        var autumn = DateComponents()
        autumn.month = 10
        autumn.day = 15
        autumn.hour = 10
        await add(id: "tires-autumn",
                  title: L.text("Winter tire season"),
                  body: L.text("Check the forecast in the app and plan your tire change."),
                  trigger: UNCalendarNotificationTrigger(dateMatching: autumn, repeats: true))

        var spring = DateComponents()
        spring.month = 4
        spring.day = 1
        spring.hour = 10
        await add(id: "tires-spring",
                  title: L.text("Summer tire season"),
                  body: L.text("Check the forecast in the app and plan your tire change."),
                  trigger: UNCalendarNotificationTrigger(dateMatching: spring, repeats: true))
    }

    /// Тестовое уведомление через 5 секунд (для демо)
    static func sendTest() async {
        await requestPermission()
        let name = L.name("Engine oil")
        let percent = 12
        await add(id: "test",
                  title: L.text("\(name): replace now"),
                  body: L.text("Only \(percent)% of its life is left. Time to replace it."),
                  trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
    }

    private static func dayTrigger(inDays days: Int) -> UNNotificationTrigger? {
        guard let date = Calendar.current.date(byAdding: .day, value: days, to: Date()) else { return nil }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = 10
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    }

    private static func add(id: String, title: String, body: String, trigger: UNNotificationTrigger?) async {
        guard let trigger else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
