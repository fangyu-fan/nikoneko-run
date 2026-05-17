import SwiftUI
import SwiftData

struct ReportView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query(sort: \RunSession.startDate, order: .reverse) private var sessions: [RunSession]
    @State private var vm = ReportViewModel()

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    periodTabs
                    dateNavRow
                    heroBlock
                    metricCards
                    BarChartView(bars: vm.chartBars)
                        .frame(height: 68)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    logList
                }
            }
            .background(theme.bg)
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { vm.loadSessions(sessions) }
        .onChange(of: sessions.count) { _, _ in vm.loadSessions(sessions) }
    }

    private var periodTabs: some View {
        HStack(spacing: 0) {
            ForEach(ReportViewModel.Period.allCases, id: \.self) { p in
                Button(p.rawValue.capitalized) { vm.period = p; vm.currentOffset = 0 }
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(vm.period == p ? theme.accent : theme.textDim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
            }
        }
        .background(theme.surface)
    }

    private var dateNavRow: some View {
        HStack {
            Button("‹") { vm.currentOffset -= 1 }.foregroundColor(theme.textDim)
            Spacer()
            Text(vm.period.rawValue).font(.system(size: 9)).foregroundColor(theme.textDim)
            Spacer()
            Button("›") {
                if vm.currentOffset < 0 { vm.currentOffset += 1 }
            }.foregroundColor(vm.currentOffset < 0 ? theme.textDim : theme.textDim.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(Int(vm.heroDuration / 60))")
                .font(.system(size: 46, weight: .ultraLight)).foregroundColor(theme.text)
            Text("min").font(.system(size: 9)).foregroundColor(theme.textDim)
            Text("DURATION").font(.system(size: 7)).tracking(1).foregroundColor(theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.top, 2)
        .padding(.bottom, 8)
    }

    private var metricCards: some View {
        let metrics: [ReportViewModel.Metric] = vm.period == .day
            ? [.distance, .calories, .steps, .hrAvg, .hrMax, .cadence]
            : [.distance, .calories, .steps]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 4) {
            ForEach(metrics, id: \.self) { metric in
                MetricCard(metric: metric, vm: vm)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var logList: some View {
        LazyVStack(spacing: 0) {
            ForEach(vm.logItems) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    LogRow(session: session, vm: vm)
                }
            }
        }
        .padding(.horizontal, 12)
    }
}

struct MetricCard: View {
    let metric: ReportViewModel.Metric
    @Bindable var vm: ReportViewModel
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }
    private var isActive: Bool { vm.selectedMetric == metric }

    var body: some View {
        Button { vm.selectedMetric = metric } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.rawValue)
                    .font(.system(size: 6.5)).foregroundColor(theme.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(9)
            .background(theme.card)
            .overlay(RoundedRectangle(cornerRadius: 9)
                .stroke(isActive ? theme.accentMid : theme.accentDim, lineWidth: isActive ? 1 : 0.5))
            .cornerRadius(9)
        }
    }
}

struct LogRow: View {
    let session: RunSession
    let vm: ReportViewModel
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5).fill(theme.bar[3])
                .frame(width: 5, height: 5)
            Text(session.startDate, format: .dateTime.month(.abbreviated).day())
                .font(.system(size: 10)).foregroundColor(theme.textMid).frame(minWidth: 32)
            Text("\(Int(session.duration / 60)) min")
                .font(.system(size: 11)).foregroundColor(theme.text)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(theme.textDim)
        }
        .padding(.vertical, 7)
        Divider().background(theme.accentDim)
    }
}
