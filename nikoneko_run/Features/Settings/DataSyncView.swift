import SwiftUI
import SwiftData
import WidgetKit
import UniformTypeIdentifiers
import HealthKit

struct DataSyncView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Query private var profiles: [UserProfile]
    @Query private var sessions: [RunSession]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    @State private var showDeleteConfirm = false
    @State private var exportURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showImportPicker = false
    @State private var showImportError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel(lm.L("dataSync.section.integrations"))
                VStack(spacing: 0) {
                    toggleRow(icon: "heart", label: lm.L("dataSync.row.appleHealth"),
                              binding: Binding(
                                get: { profile?.healthKitEnabled ?? false },
                                set: { v in
                                    profile?.healthKitEnabled = v
                                    try? ctx.save()
                                    if v { Task { await HealthKitService.shared.requestPermissions() } }
                                }
                              ))
                    Rectangle().fill(theme.accentDim).frame(height: 0.5)
                    toggleRow(icon: "icloud", label: lm.L("dataSync.row.iCloud"),
                              binding: Binding(
                                get: { profile?.iCloudEnabled ?? true },
                                set: { v in
                                    profile?.iCloudEnabled = v
                                    UserDefaults.standard.set(v, forKey: "iCloudEnabled")
                                    try? ctx.save()
                                }
                              ))
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.bottom, 4)

                sectionLabel(lm.L("dataSync.section.data"))
                VStack(spacing: 0) {
                    actionRow(icon: "arrow.up.doc", label: lm.L("dataSync.row.exportCSV"), color: theme.text) {
                        if let url = HealthKitService.shared.exportCSV(sessions: sessions) {
                            exportURL = url
                            showShareSheet = true
                        }
                    }
                    Rectangle().fill(theme.accentDim).frame(height: 0.5)
                    actionRow(icon: "arrow.down.doc", label: lm.L("dataSync.row.importCSV"), color: theme.text) {
                        showImportPicker = true
                    }
                    Rectangle().fill(theme.accentDim).frame(height: 0.5)
                    actionRow(icon: "trash", label: lm.L("dataSync.row.clearAll"), color: Color.red.opacity(0.8)) {
                        showDeleteConfirm = true
                    }
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .background(theme.bg.ignoresSafeArea())
        .id(lm.version)
        .onAppear { syncHealthKitStatus() }
        .navigationTitle(lm.L("dataSync.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importCSV(from: url)
            case .failure:
                showImportError = true
            }
        }
        .alert(lm.L("dataSync.import.error"), isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        }
        .alert(lm.L("dataSync.confirm.title"), isPresented: $showDeleteConfirm) {
            Button(lm.L("dataSync.confirm.delete"), role: .destructive) {
                for session in sessions { ctx.delete(session) }
                try? ctx.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
            Button(lm.L("dataSync.confirm.cancel"), role: .cancel) {}
        }
    }

    // MARK: - HealthKit Status Sync

    private func syncHealthKitStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let store = HKHealthStore()
        let type = HKQuantityType(.heartRate)
        let status = store.authorizationStatus(for: type)
        if status == .sharingAuthorized && profile?.healthKitEnabled == false {
            profile?.healthKitEnabled = true
            try? ctx.save()
        }
    }

    // MARK: - CSV Import

    private func importCSV(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showImportError = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            showImportError = true
            return
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { showImportError = true; return }

        let df = ISO8601DateFormatter()
        var imported = 0

        for line in lines.dropFirst() {  // skip header
            let cols = line.components(separatedBy: ",")
            guard cols.count >= 8,
                  let date = df.date(from: cols[0]),
                  let durationMin = Double(cols[1]),
                  let distanceKm = Double(cols[2]),
                  let calories = Double(cols[3]),
                  let steps = Int(cols[4]),
                  let avgHR = Int(cols[5]),
                  let maxHR = Int(cols[6]),
                  let bpm = Int(cols[7])
            else { continue }

            // Skip duplicate (same startDate already exists)
            let exists = sessions.contains { abs($0.startDate.timeIntervalSince(date)) < 1 }
            if exists { continue }

            let session = RunSession(
                startDate: date,
                duration: durationMin * 60,
                distance: distanceKm * 1000,
                calories: calories,
                steps: steps,
                avgHR: avgHR,
                maxHR: maxHR,
                avgCadence: 0,
                bpm: bpm,
                characterId: "loader_cat",
                themeId: "obsidian"
            )
            ctx.insert(session)
            imported += 1
        }

        if imported > 0 {
            try? ctx.save()
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            showImportError = true
        }
    }

    // MARK: - Row helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 10)
            .padding(.bottom, 5)
            .padding(.horizontal, 2)
    }

    private func toggleRow(icon: String, label: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(theme.text)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(theme.text)
            Spacer()
            Toggle("", isOn: binding)
                .tint(theme.accent)
                .labelsHidden()
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    private func actionRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
