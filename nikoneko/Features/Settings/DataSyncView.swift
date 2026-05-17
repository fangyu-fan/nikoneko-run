import SwiftUI
import SwiftData

struct DataSyncView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            Toggle("Apple Health", isOn: Binding(
                get: { profile?.healthKitEnabled ?? false },
                set: { v in profile?.healthKitEnabled = v; try? ctx.save() }
            )).tint(theme.accent)

            Toggle("iCloud Sync", isOn: Binding(
                get: { profile?.iCloudEnabled ?? false },
                set: { v in
                    profile?.iCloudEnabled = v
                    UserDefaults.standard.set(v, forKey: "iCloudEnabled")
                    try? ctx.save()
                }
            )).tint(theme.accent)

            Button("Export CSV") { /* wired in K-01 */ }
                .foregroundColor(theme.accent)

            Button("Clear All Data", role: .destructive) { showDeleteConfirm = true }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.bg)
        .navigationTitle("Data & Sync")
        .confirmationDialog("Delete all run data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) { /* wired in K-01 */ }
            Button("Cancel", role: .cancel) {}
        }
    }
}
