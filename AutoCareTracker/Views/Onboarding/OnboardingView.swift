import SwiftUI
import SwiftData

/// Добавить машину: марка, модель, год, пробег и когда менялись расходники
struct OnboardingView: View {
    @Environment(\.modelContext) private var context

    @State private var nickname = ""
    @State private var brand = ""
    @State private var model = ""
    @State private var yearText = ""
    @State private var mileageText = ""
    @State private var selected: Set<String> = Set(DefaultComponents.all.map { $0.name })
    @State private var lastKm: [String: String] = [:]
    @State private var lastDate: [String: Date] = [:]
    @State private var showBrands = false
    @State private var showModels = false

    private var mileage: Int? { Int(mileageText) }

    /// Пробег последней замены: пусто = не больше текущего пробега
    private func kmValid(_ name: String) -> Bool {
        guard let text = lastKm[name], !text.isEmpty else { return true }
        guard let v = Int(text), let m = mileage else { return false }
        return v <= m
    }

    private var canSave: Bool {
        !brand.isEmpty && !model.isEmpty && mileage != nil && !selected.isEmpty
            && selected.allSatisfy { kmValid($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add your car").font(.largeTitle.bold())

                TextField("Nickname (optional)", text: $nickname).fieldStyle()

                HStack(spacing: 12) {
                    selector("Brand", value: brand, placeholder: "e.g. Toyota") { showBrands = true }
                    selector("Model", value: model, placeholder: "Pick brand first", enabled: !brand.isEmpty) { showModels = true }
                }
                HStack(spacing: 12) {
                    TextField("Year", text: $yearText).keyboardType(.numberPad).fieldStyle()
                    TextField("Odometer, km", text: $mileageText).keyboardType(.numberPad).fieldStyle()
                }

                Text("What to track").font(.title3.bold()).padding(.top, 8)
                Text("When was each part last replaced? Leave km empty if it was just replaced.")
                    .font(.footnote).foregroundStyle(.secondary)

                ForEach(DefaultComponents.all, id: \.name) { item in
                    partRow(item.name)
                }

                Button("Add car") { save() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSave)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .onChange(of: brand) { model = "" }
        .sheet(isPresented: $showBrands) {
            PickerSheet(title: "Select brand", items: CarCatalog.brands, selection: $brand)
        }
        .sheet(isPresented: $showModels) {
            PickerSheet(title: "Select model", items: CarCatalog.models(for: brand), selection: $model)
        }
    }

    private func partRow(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(L.name(name), isOn: Binding(
                get: { selected.contains(name) },
                set: { on in
                    if on { selected.insert(name) } else { selected.remove(name) }
                }
            ))
            .tint(.brand)

            if selected.contains(name) {
                HStack(spacing: 12) {
                    TextField("Replaced at, km", text: Binding(
                        get: { lastKm[name] ?? "" },
                        set: { lastKm[name] = $0 }
                    ))
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.18)))

                    DatePicker("", selection: Binding(
                        get: { lastDate[name] ?? Date() },
                        set: { lastDate[name] = $0 }
                    ), in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                }
                if !kmValid(name) {
                    Text("Can’t be more than the current odometer.")
                        .font(.caption).foregroundStyle(.red)
                }
            }
        }
        .fieldStyle()
    }

    private func selector(_ title: LocalizedStringKey, value: String, placeholder: LocalizedStringKey,
                          enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    if value.isEmpty {
                        Text(placeholder).foregroundStyle(.secondary).lineLimit(1)
                    } else {
                        Text(value).lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.down").foregroundStyle(.secondary)
            }
            .fieldStyle()
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }

    private func save() {
        guard let mileage else { return }
        let name = nickname.isEmpty ? "\(brand) \(model)" : nickname
        let car = Car(name: name, currentMileage: mileage,
                      brand: brand, model: model, year: Int(yearText) ?? 0)
        for item in DefaultComponents.all where selected.contains(item.name) {
            let km = Int(lastKm[item.name] ?? "") ?? mileage
            car.components.append(Component(name: item.name,
                                            intervalKm: item.intervalKm,
                                            lastServiceKm: km,
                                            lastServiceDate: lastDate[item.name] ?? Date()))
        }
        context.insert(car)
    }
}
