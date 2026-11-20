import Foundation

/// Короткий справочник популярных марок и моделей (можно расширять)
enum CarCatalog {
    static let models: [String: [String]] = [
        "Toyota": ["Camry", "Corolla", "RAV4", "Land Cruiser", "Prado", "Highlander", "Avensis"],
        "Lexus": ["ES", "IS", "LS", "GS", "NX", "RX", "GX", "LX"],
        "Hyundai": ["Accent", "Elantra", "Sonata", "Tucson", "Santa Fe", "Solaris"],
        "Kia": ["Rio", "Cerato", "Optima", "Sportage", "Sorento", "K5"],
        "Chevrolet": ["Lacetti", "Cruze", "Aveo", "Cobalt", "Nexia", "Malibu"],
        "Daewoo": ["Nexia", "Matiz", "Gentra"],
        "Nissan": ["Almera", "Teana", "X-Trail", "Qashqai", "Juke", "Patrol"],
        "Mazda": ["3", "6", "CX-5", "CX-7"],
        "Honda": ["Civic", "Accord", "CR-V", "Fit"],
        "Mitsubishi": ["Lancer", "Outlander", "Pajero", "ASX"],
        "Volkswagen": ["Polo", "Passat", "Golf", "Tiguan", "Jetta"],
        "BMW": ["3 Series", "5 Series", "7 Series", "X3", "X5"],
        "Mercedes-Benz": ["C-Class", "E-Class", "S-Class", "GLE", "ML"],
        "Audi": ["A4", "A6", "A8", "Q5", "Q7"],
        "Skoda": ["Octavia", "Rapid", "Superb", "Kodiaq"],
        "Ford": ["Focus", "Fiesta", "Mondeo", "Explorer"],
        "Lada": ["Granta", "Vesta", "Niva", "Priora"],
        "Subaru": ["Impreza", "Forester", "Outback", "Legacy"],
        "Renault": ["Logan", "Duster", "Sandero", "Megane"]
    ]

    static var brands: [String] { models.keys.sorted() }
    static func models(for brand: String) -> [String] { models[brand] ?? [] }
}
