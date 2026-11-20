import SwiftUI

/// Окно выбора с поиском (марка / модель)
struct PickerSheet: View {
    let title: LocalizedStringKey
    let items: [String]
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [String] {
        search.isEmpty ? items : items.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered, id: \.self) { item in
                    Button(item) { selection = item; dismiss() }
                        .foregroundStyle(.primary)
                }
                // Если нужного нет в списке, можно ввести своё
                if filtered.isEmpty && !search.isEmpty {
                    Button("Use “\(search)”") { selection = search; dismiss() }
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }
}
