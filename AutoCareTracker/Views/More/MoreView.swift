import SwiftUI

/// Вкладка «Ещё»: профиль, машина, о приложении, выход
struct MoreView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.modelContext) private var context
    @State private var demoLoaded = false
    @AppStorage(L.key, store: L.store) private var language = "system"
    @AppStorage("userEmail") private var email = ""
    let car: Car
    @State private var showEditCar = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    profileCard

                    Text("ACCOUNT")
                        .font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        .tracking(1.5).padding(.top, 8)

                    VStack(spacing: 0) {
                        Button { showEditCar = true } label: {
                            MoreRow(icon: "car.fill", color: .brand,
                                    title: "My car", subtitle: "Edit name and mileage")
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 72)
                        Menu {
                            ForEach(L.options) { option in
                                Button {
                                    language = option.code
                                } label: {
                                    if option.code == language {
                                        Label(option.title, systemImage: "checkmark")
                                    } else {
                                        Text(option.title)
                                    }
                                }
                            }
                        } label: {
                            MoreRow(icon: "globe", color: .blue, title: "Language",
                                    subtitle: LocalizedStringKey(L.title(for: language)))
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 72)
                        Button { Task { await NotificationManager.sendTest() } } label: {
                            MoreRow(icon: "bell.fill", color: .orange, title: "Test notification",
                                    subtitle: "Arrives in 5 seconds. Close the app to see it")
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 72)
                        Button { loadDemoHistory() } label: {
                            MoreRow(icon: "chart.line.uptrend.xyaxis", color: .green,
                                    title: demoLoaded ? "Demo history added" : "Demo: mileage history",
                                    subtitle: "Sample 30-day log (45 km a day) to show forecasts",
                                    showsChevron: false)
                        }
                        .buttonStyle(.plain)
                        .disabled(demoLoaded)
                        Divider().padding(.leading, 72)
                        MoreRow(icon: "info.circle", color: .gray,
                                title: "About", subtitle: "Version \(version)", showsChevron: false)
                    }
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.1)))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(white: 0.18)))

                    Button { auth.signOut() } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity).padding(.vertical, 18)
                            .foregroundStyle(.red)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.red.opacity(0.1)))
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditCar) { EditCarView(car: car) }
        }
    }

    /// ДЕМО: добавляет запись пробега 30 дней назад, как будто машина
    /// проезжала 45 км в день. Нужна, чтобы показать прогноз на защите.
    private func loadDemoHistory() {
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        context.insert(OdometerEntry(date: monthAgo, km: max(0, car.currentMileage - 1350)))
        demoLoaded = true
    }

    private var profileCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.fill")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Color.white.opacity(0.25)))
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back").font(.subheadline).foregroundStyle(.white.opacity(0.8))
                Text(email.isEmpty ? L.text("Driver") : email)
                    .font(.headline).foregroundStyle(.white).lineLimit(1)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24).fill(
                LinearGradient(colors: [Color.brand, Color.cyan],
                               startPoint: .leading, endPoint: .trailing))
        )
    }
}

struct MoreRow: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var showsChevron = true

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.18)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if showsChevron { Image(systemName: "chevron.right").foregroundStyle(.secondary) }
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}
