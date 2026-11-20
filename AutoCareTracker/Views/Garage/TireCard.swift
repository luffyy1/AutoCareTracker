import SwiftUI

/// Карточка «Шины»: какие стоят и когда пора менять
struct TireCard: View {
    let tires: TireAdvisor

    private var accent: Color {
        if tires.current == nil { return .brand }
        return tires.needsSwitch ? .orange : .green
    }

    private var icon: String {
        tires.recommended == .winter ? "snowflake" : "sun.max.fill"
    }

    private var title: String {
        guard let current = tires.current else { return L.text("Which tires are on now?") }
        if tires.needsSwitch { return tires.recommended.timeForText }
        return current.allGoodText
    }

    private var subtitle: String {
        if tires.usesWeather, let temp = tires.avgTemp {
            let city = L.name(tires.cityName)
            let degrees = String(format: "%+.0f", temp)
            var text = L.text("Next 7 days in \(city): average \(degrees) °C.")
            if let snow = tires.snowDate {
                let day = snow.formatted(.dateTime.weekday(.wide).day().month().locale(L.locale))
                text += " " + L.text("Snow expected on \(day).")
            }
            return text
        }
        return L.text("No fresh forecast, using the calendar: winter season is mid-October to end of March.")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(accent)
                    .frame(width: 48, height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(accent.opacity(0.18)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
            }

            if tires.current == nil {
                HStack(spacing: 12) {
                    Button("Summer") { tires.setCurrent(.summer) }
                    Button("Winter") { tires.setCurrent(.winter) }
                }
                .buttonStyle(.bordered)
            } else if tires.needsSwitch {
                Button(tires.recommended.switchedText) {
                    tires.setCurrent(tires.recommended)
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Menu {
                    ForEach(Cities.all) { city in
                        Button(L.name(city.name)) {
                            tires.setCity(city.name)
                            Task { await tires.refresh() }
                        }
                    }
                } label: {
                    Label(L.name(tires.cityName), systemImage: "location.fill").font(.caption)
                }
                Spacer()
                Text("Rule: below +7 °C means winter tires")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.5)))
    }
}
