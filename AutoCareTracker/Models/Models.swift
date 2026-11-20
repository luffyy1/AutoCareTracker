import Foundation
import SwiftData

/// Автомобиль пользователя
@Model
final class Car {
    var name: String
    var currentMileage: Int
    var brand: String = ""
    var model: String = ""
    var year: Int = 0
    @Relationship(deleteRule: .cascade) var components: [Component] = []

    init(name: String, currentMileage: Int, brand: String = "", model: String = "", year: Int = 0) {
        self.name = name
        self.currentMileage = currentMileage
        self.brand = brand
        self.model = model
        self.year = year
    }
}

/// Расходник: масло, колодки, фильтры, свечи
@Model
final class Component {
    var name: String
    var intervalKm: Int        // интервал замены
    var lastServiceKm: Int     // пробег при последней замене
    var lastServiceDate: Date = Date()   // дата последней замены

    init(name: String, intervalKm: Int, lastServiceKm: Int, lastServiceDate: Date = Date()) {
        self.name = name
        self.intervalKm = intervalKm
        self.lastServiceKm = lastServiceKm
        self.lastServiceDate = lastServiceDate
    }
}

/// Запись пробега с датой: по ним считается средний пробег в день
@Model
final class OdometerEntry {
    var date: Date
    var km: Int

    init(date: Date = Date(), km: Int) {
        self.date = date
        self.km = km
    }
}

/// Заводские интервалы по умолчанию (примерные, потом можно уточнить)
enum DefaultComponents {
    static let all: [(name: String, intervalKm: Int)] = [
        ("Engine oil", 10_000),
        ("Brake pads", 40_000),
        ("Filters", 15_000),
        ("Spark plugs", 30_000)
    ]
}
