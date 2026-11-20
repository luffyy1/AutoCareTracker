import Foundation

/// Язык приложения. Пользователь выбирает его во вкладке More.
/// "system" значит «как в телефоне».
enum L {
    static let key = "app.language"

    /// Общие настройки приложения и виджета (App Group), чтобы виджет знал выбранный язык
    static let store = UserDefaults(suiteName: WidgetSnapshot.appGroup)

    struct Option: Identifiable {
        let code: String
        let title: String
        var id: String { code }
    }

    static var options: [Option] {
        [Option(code: "system", title: text("Same as phone")),
         Option(code: "en", title: "English"),
         Option(code: "ru", title: "Русский"),
         Option(code: "kk", title: "Қазақша")]
    }

    static func title(for code: String) -> String {
        options.first { $0.code == code }?.title ?? code
    }

    /// Текущий выбор: "system", "en", "ru" или "kk"
    static var code: String { store?.string(forKey: key) ?? "system" }

    static func locale(for code: String) -> Locale {
        code == "system" ? Locale.current : Locale(identifier: code)
    }

    static var locale: Locale { locale(for: code) }

    /// Папка с переводом выбранного языка внутри приложения
    static var bundle: Bundle {
        let code = self.code
        if code == "system" { return .main }
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        // Для английского отдельной папки может не быть: берём папку без переводов,
        // тогда текст остаётся таким, как написан в коде, то есть английским
        if code == "en" { return Bundle(path: NSTemporaryDirectory()) ?? .main }
        return .main
    }

    /// Перевод фразы на выбранный язык
    static func text(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: bundle, locale: locale)
    }

    /// Переводит стандартное название (деталь, город).
    /// Если это своё название пользователя, оно остаётся как есть.
    static func name(_ raw: String) -> String {
        text(String.LocalizationValue(raw))
    }
}
