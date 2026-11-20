import SwiftUI
import SwiftData

/// Добавить свой расходник (ремень ГРМ, антифриз и т.д.)
struct AddComponentView: View {
    @Environment(\.dismiss) private var dismiss
    let car: Car

    @State private var name = ""
    @State private var intervalText = ""
    @State private var lastServiceText = ""
    @State private var date = Date()

    private let suggestions: [(String, Int)] = [
        ("Timing belt", 90_000), ("Coolant", 60_000), ("Transmission fluid", 60_000)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick add") {
                    ForEach(suggestions, id: \.0) { s in
                        Button(L.name(s.0)) { name = L.name(s.0); intervalText = String(s.1) }
                    }
                }
                Section("Part") {
                    TextField("Name", text: $name)
                    TextField("Replace every, km", text: $intervalText).keyboardType(.numberPad)
                    TextField("Last replaced at, km", text: $lastServiceText).keyboardType(.numberPad)
                    DatePicker("Last replaced on", selection: $date, in: ...Date(), displayedComponents: .date)
                }
            }
            .navigationTitle("New part")
            .onAppear { lastServiceText = String(car.currentMileage) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let interval = Int(intervalText), let last = Int(lastServiceText) {
                            car.components.append(Component(name: name, intervalKm: interval, lastServiceKm: last, lastServiceDate: date))
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || Int(intervalText) == nil || Int(lastServiceText) == nil)
                }
            }
        }
    }
}

/// Изменить название и пробег машины
struct EditCarView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var car: Car

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $car.name)
                    TextField("Mileage, km", value: $car.currentMileage, format: .number.grouping(.never))
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit car")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

/// Изменить расходник или удалить его
struct EditComponentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var component: Component

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // В поле показываем перевод стандартного названия
                    TextField("Name", text: Binding(
                        get: { L.name(component.name) },
                        set: { component.name = $0 }
                    ))
                    TextField("Replace every, km", value: $component.intervalKm, format: .number.grouping(.never))
                        .keyboardType(.numberPad)
                    TextField("Last replaced at, km", value: $component.lastServiceKm, format: .number.grouping(.never))
                        .keyboardType(.numberPad)
                    DatePicker("Last replaced on", selection: $component.lastServiceDate, in: ...Date(), displayedComponents: .date)
                }
                Section {
                    Button("Delete part", role: .destructive) {
                        context.delete(component)
                        dismiss()
                    }
                }
            }
            .navigationTitle(L.name(component.name))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
