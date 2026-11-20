import SwiftUI
import SwiftData

/// Главный экран «Мой гараж»: карточка машины + список расходников
struct DashboardView: View {
    @Bindable var car: Car
    let kmPerDay: Double?
    let tires: TireAdvisor
    @State private var showUpdate = false
    @State private var input = ""
    @State private var showAdd = false
    @State private var editing: Component?

    private var statuses: [WearStatus] {
        car.components.map {
            WearEngine.status(for: WearEngine.remainingPercent(for: $0, currentMileage: car.currentMileage))
        }
    }
    private func count(_ s: WearStatus) -> Int { statuses.filter { $0 == s }.count }

    private var overall: (text: String, color: Color) {
        if statuses.isEmpty { return (L.text("No parts"), .gray) }
        if count(.red) > 0 { return (L.text("Service needed"), .red) }
        if count(.yellow) > 0 { return (L.text("Plan service"), .yellow) }
        return (L.text("All good"), .green)
    }

    private var subtitle: String {
        [car.year > 0 ? String(car.year) : "", car.brand, car.model]
            .filter { !$0.isEmpty }.joined(separator: " ")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    carCard

                    Text("SEASON")
                        .font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        .tracking(1.5).padding(.top, 8)
                    TireCard(tires: tires)

                    Text("PARTS")
                        .font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        .tracking(1.5).padding(.top, 8)

                    ForEach(car.components) { c in
                        ComponentCard(component: c, mileage: car.currentMileage, kmPerDay: kmPerDay) {
                            c.lastServiceKm = car.currentMileage
                            c.lastServiceDate = Date()
                        }
                        .onTapGesture { editing = c }
                    }
                    if car.components.isEmpty {
                        Text("No parts yet. Tap + to add one.")
                            .foregroundStyle(.secondary).padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("My garage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .alert("Update mileage", isPresented: $showUpdate) {
                TextField("km", text: $input).keyboardType(.numberPad)
                Button("Save") {
                    if let v = Int(input), v >= car.currentMileage { car.currentMileage = v }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showAdd) { AddComponentView(car: car) }
            .sheet(item: $editing) { EditComponentView(component: $0) }
        }
    }

    private var carCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(car.name).font(.title.bold())
                    if !subtitle.isEmpty { Text(subtitle).foregroundStyle(.secondary) }
                }
                Spacer()
                Text(overall.text)
                    .font(.footnote.bold())
                    .foregroundStyle(overall.color)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(overall.color.opacity(0.15)))
                    .overlay(Capsule().stroke(overall.color.opacity(0.5)))
            }
            HStack {
                Image(systemName: "car.fill").font(.system(size: 44)).foregroundStyle(Color.brand)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Odometer").font(.caption).foregroundStyle(.secondary)
                    Text("\(car.currentMileage) km").font(.title2.bold())
                }
            }
            HStack(spacing: 12) {
                stat(count(.green), "Good", .green)
                stat(count(.yellow), "Soon", .yellow)
                stat(count(.red), "Urgent", .red)
            }
            Button("Update mileage") {
                input = String(car.currentMileage)
                showUpdate = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24).fill(
                LinearGradient(colors: [Color(white: 0.13), Color(red: 0.08, green: 0.08, blue: 0.2)],
                               startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(white: 0.2)))
    }

    private func stat(_ n: Int, _ label: LocalizedStringKey, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(n)").font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.1)))
    }
}

struct ComponentCard: View {
    let component: Component
    let mileage: Int
    let kmPerDay: Double?
    var onReplace: () -> Void

    private var percent: Int { WearEngine.remainingPercent(for: component, currentMileage: mileage) }
    private var color: Color { WearEngine.status(for: percent).color }
    private var used: Int { max(0, mileage - component.lastServiceKm) }
    private var overdueKm: Int { max(0, used - component.intervalKm) }
    private var kmLeft: Int { max(0, component.intervalKm - used) }

    /// «≈ 23 days · 5 Dec» или nil, если прогноза ещё нет
    private var forecastText: String? {
        guard overdueKm == 0,
              let days = Forecast.daysLeft(for: component, mileage: mileage, kmPerDay: kmPerDay)
        else { return nil }
        let date = Forecast.dueDate(daysLeft: days).formatted(.dateTime.day().month().locale(L.locale))
        return "≈ " + L.text("\(days) days left") + " · " + date
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(percent) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(percent)%").font(.caption.bold())
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(L.name(component.name)).font(.headline)
                if overdueKm > 0 {
                    Text("Overdue by \(overdueKm) km")
                        .font(.subheadline.bold()).foregroundStyle(.red)
                } else {
                    Text("\(kmLeft) km left")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                if let forecastText {
                    Text(forecastText).font(.subheadline.bold()).foregroundStyle(color)
                }
                Text("Last replaced: \(component.lastServiceDate.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(L.locale)))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Replaced", action: onReplace).buttonStyle(.bordered)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(white: 0.18)))
    }
}
