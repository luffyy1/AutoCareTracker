import Foundation
import Observation

enum TireKind: String {
    case summer, winter

    // Целые фразы, а не склейка из слов: так перевод получается грамотным

    var timeForText: String {
        self == .winter ? L.text("Time for winter tires")
                        : L.text("Time for summer tires")
    }

    var allGoodText: String {
        self == .winter ? L.text("Winter tires: all good")
                        : L.text("Summer tires: all good")
    }

    var switchedText: String {
        self == .winter ? L.text("I switched to winter tires")
                        : L.text("I switched to summer tires")
    }
}

struct City: Identifiable, Hashable {
    let name: String
    let lat: Double
    let lon: Double
    var id: String { name }
}

/// Города Казахстана (координаты примерные, для прогноза погоды этого хватает)
enum Cities {
    static let all: [City] = [
        City(name: "Almaty", lat: 43.24, lon: 76.89),
        City(name: "Astana", lat: 51.17, lon: 71.43),
        City(name: "Shymkent", lat: 42.32, lon: 69.59),
        City(name: "Kaskelen", lat: 43.20, lon: 76.62),
        City(name: "Karaganda", lat: 49.80, lon: 73.10),
        City(name: "Aktobe", lat: 50.28, lon: 57.17),
        City(name: "Taraz", lat: 42.90, lon: 71.37),
        City(name: "Pavlodar", lat: 52.29, lon: 76.97),
        City(name: "Oskemen", lat: 49.95, lon: 82.61),
        City(name: "Semey", lat: 50.41, lon: 80.23),
        City(name: "Atyrau", lat: 47.11, lon: 51.92),
        City(name: "Kostanay", lat: 53.21, lon: 63.63),
        City(name: "Kyzylorda", lat: 44.85, lon: 65.51),
        City(name: "Oral", lat: 51.23, lon: 51.37),
        City(name: "Petropavl", lat: 54.87, lon: 69.14),
        City(name: "Aktau", lat: 43.65, lon: 51.17),
        City(name: "Taldykorgan", lat: 45.02, lon: 78.37),
        City(name: "Turkistan", lat: 43.30, lon: 68.25)
    ]
}

/// Советует, когда менять шины.
/// С интернетом: по прогнозу погоды на 7 дней (правило +7 °C).
/// Без интернета: по календарю.
@MainActor @Observable
final class TireAdvisor {
    /// Порог: ниже этой средней температуры нужна зимняя резина
    static let threshold = 7.0
    /// Сколько дней сохранённый прогноз считается свежим
    private static let freshDays = 3.0

    private(set) var current: TireKind?
    private(set) var cityName: String
    private(set) var avgTemp: Double? = nil
    private(set) var snowDate: Date? = nil
    private(set) var updatedAt: Date? = nil

    private let defaults = UserDefaults.standard

    init() {
        let saved = UserDefaults.standard
        current = TireKind(rawValue: saved.string(forKey: "tires.current") ?? "")
        cityName = saved.string(forKey: "tires.city") ?? "Almaty"
        if let date = saved.object(forKey: "tires.updatedAt") as? Date {
            updatedAt = date
            avgTemp = saved.object(forKey: "tires.avgTemp") as? Double
            snowDate = saved.object(forKey: "tires.snowDate") as? Date
        }
    }

    /// Есть ли свежий прогноз погоды
    var usesWeather: Bool {
        guard avgTemp != nil, let updatedAt else { return false }
        return Date().timeIntervalSince(updatedAt) < Self.freshDays * 86_400
    }

    var recommended: TireKind {
        if usesWeather, let avgTemp {
            return avgTemp < Self.threshold ? .winter : .summer
        }
        return Self.calendarSeason(Date())
    }

    /// true, если стоят не те шины, что советует прогноз
    var needsSwitch: Bool {
        guard let current else { return false }
        return current != recommended
    }

    /// Запасной вариант без интернета: зима с 15 октября по 31 марта (примерно)
    static func calendarSeason(_ date: Date) -> TireKind {
        let c = Calendar.current.dateComponents([.month, .day], from: date)
        let monthDay = (c.month ?? 1) * 100 + (c.day ?? 1)
        return (monthDay >= 1015 || monthDay < 401) ? .winter : .summer
    }

    func setCurrent(_ kind: TireKind) {
        current = kind
        defaults.set(kind.rawValue, forKey: "tires.current")
    }

    func setCity(_ name: String) {
        cityName = name
        defaults.set(name, forKey: "tires.city")
        // Прогноз старого города больше не подходит
        avgTemp = nil
        snowDate = nil
        updatedAt = nil
        defaults.removeObject(forKey: "tires.updatedAt")
    }

    /// Загружает прогноз на 7 дней с open-meteo.com (бесплатно, без ключа).
    /// Если интернета нет, остаёмся на календаре.
    func refresh() async {
        guard let city = Cities.all.first(where: { $0.name == cityName }) else { return }
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        comps?.queryItems = [
            URLQueryItem(name: "latitude", value: String(city.lat)),
            URLQueryItem(name: "longitude", value: String(city.lon)),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,snowfall_sum"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]
        guard let url = comps?.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let daily = try JSONDecoder().decode(WeatherResponse.self, from: data).daily

            // Средняя температура недели = среднее из (макс + мин) / 2 по дням
            var means: [Double] = []
            for (maxT, minT) in zip(daily.maxTemps, daily.minTemps) {
                if let maxT, let minT { means.append((maxT + minT) / 2) }
            }
            guard !means.isEmpty, city.name == cityName else { return }

            // Первый день, когда ожидается снег
            let parser = DateFormatter()
            parser.dateFormat = "yyyy-MM-dd"
            parser.locale = Locale(identifier: "en_US_POSIX")
            var firstSnow: Date?
            for (day, snow) in zip(daily.time, daily.snowfall) {
                if let snow, snow > 0, let date = parser.date(from: day) {
                    firstSnow = date
                    break
                }
            }

            avgTemp = means.reduce(0, +) / Double(means.count)
            snowDate = firstSnow
            updatedAt = Date()
            defaults.set(avgTemp, forKey: "tires.avgTemp")
            defaults.set(updatedAt, forKey: "tires.updatedAt")
            if let firstSnow {
                defaults.set(firstSnow, forKey: "tires.snowDate")
            } else {
                defaults.removeObject(forKey: "tires.snowDate")
            }
        } catch {
            // Нет сети или сервис недоступен: работаем по календарю
        }
    }
}

private struct WeatherResponse: Decodable {
    let daily: Daily

    struct Daily: Decodable {
        let time: [String]
        let maxTemps: [Double?]
        let minTemps: [Double?]
        let snowfall: [Double?]

        enum CodingKeys: String, CodingKey {
            case time
            case maxTemps = "temperature_2m_max"
            case minTemps = "temperature_2m_min"
            case snowfall = "snowfall_sum"
        }
    }
}
