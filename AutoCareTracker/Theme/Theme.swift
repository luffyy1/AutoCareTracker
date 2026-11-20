import SwiftUI

extension Color {
    /// Индиго, как в референсе
    static let brand = Color(red: 0.39, green: 0.40, blue: 0.95)
}

extension View {
    /// Тёмное скруглённое поле ввода
    func fieldStyle() -> some View {
        self.padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.12)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(white: 0.2)))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.brand))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}
