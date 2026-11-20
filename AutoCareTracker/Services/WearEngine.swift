import SwiftUI

enum WearStatus {
    case green, yellow, red

    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }
}

/// Ядро приложения: считает остаток ресурса в процентах
enum WearEngine {

    /// 100 = только что заменили, 0 = пора менять или просрочено
    static func remainingPercent(for c: Component, currentMileage: Int) -> Int {
        guard c.intervalKm > 0 else { return 0 }
        let used = max(0, currentMileage - c.lastServiceKm)
        let remaining = 1.0 - Double(used) / Double(c.intervalKm)
        return max(0, min(100, Int((remaining * 100).rounded())))
    }

    /// Светофор: 80–100 зелёный, 20–79 жёлтый, 0–19 красный
    static func status(for percent: Int) -> WearStatus {
        switch percent {
        case 80...: return .green
        case 20..<80: return .yellow
        default: return .red
        }
    }
}
