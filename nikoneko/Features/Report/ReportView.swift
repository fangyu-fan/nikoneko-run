import SwiftUI
import SwiftData

struct ReportView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query(sort: \RunSession.startDate, order: .reverse) private var sessions: [RunSession]
    @State private var vm = ReportViewModel()

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                periodTabs
                dateNavRow
                heroBlock
                metricCards
                BarChartView(bars: vm.chartBars)
                    .frame(height: 68)
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                logList
            }
        }
        .background(theme.bg.ignoresSafeArea())
        .onAppear { vm.loadSessions(sessions) }
        .onChange(of: sessions.count) { _, _ in vm.loadSessions(sessions) }
    }

    // MARK: - Period tabs

    private var periodTabs: some View {
        HStack(spacing: 0) {
            ForEach(ReportViewModel.Period.allCases, id: \.self) { p in
                Button(action: { vm.period = p; vm.currentOffset = 0 }) {
                    VStack(spacing: 0) {
                        Text(p.rawValue.capitalized)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(vm.period == p ? theme.accent : theme.textDim)
                            .padding(.vertical, 9)
                        Rectangle()
                            .fill(vm.period == p ? theme.accent : Color.clear)
                            .frame(height: 1.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(theme.surface)
    }

    // MARK: - Date nav row

    private var dateNavRow: some View {
        HStack {
            Button("‹") { vm.currentOffset -= 1 }
                .font(.system(size: 14))
                .foregroundColor(theme.textDim)
            Spacer()
            Text(vm.dateRangeLabel)
                .font(.system(size: 9))
                .foregroundColor(theme.textDim)
            Spacer()
            Button("›") { if vm.currentOffset < 0 { vm.currentOffset += 1 } }
                .font(.system(size: 14))
                .foregroundColor(vm.currentOffset < 0 ? theme.textDim : theme.textDim.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    // MARK: - Hero block

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(heroText)
                    .font(.system(size: 46, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                Text(heroUnit)
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
            }
            Text("DURATION")
                .font(.system(size: 7))
                .tracking(1)
                .foregroundColor(theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.top, 2)
        .padding(.bottom, 8)
    }

    private var heroText: String {
        let seconds = vm.heroDuration
        if seconds < 3600 { return "\(Int(seconds / 60))" }
        return String(format: "%.1f", seconds / 3600)
    }

    private var heroUnit: String {
        vm.heroDuration < 3600 ? "min" : "hrs"
    }

    // MARK: - Metric cards

    private var metricCards: some View {
        let metrics: [ReportViewModel.Metric] = vm.period == .day
            ? [.distance, .calories, .steps, .hrAvg, .hrMax, .cadence]
            : [.distance, .calories, .steps]

        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
            spacing: 4
        ) {
            ForEach(metrics, id: \.self) { metric in
                MetricCard(metric: metric, vm: vm)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Log list

    private var logList: some View {
        LazyVStack(spacing: 0) {
            ForEach(vm.logItems) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    LogRow(session: session, vm: vm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - MetricCard

struct MetricCard: View {
    let metric: ReportViewModel.Metric
    @Bindable var vm: ReportViewModel
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }
    private var isActive: Bool { vm.selectedMetric == metric }

    var body: some View {
        Button(action: { vm.selectedMetric = metric }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.metricIcon(metric))
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
                Text(vm.metricValueString(metric))
                    .font(.system(size: 13, weight: .ultraLight))
                    .foregroundColor(isActive ? theme.accent : theme.textMid)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(vm.metricLabel(metric))
                    .font(.system(size: 6.5))
                    .foregroundColor(theme.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(9)
            .background(theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(
                        isActive ? theme.accentMid : theme.accentDim,
                        lineWidth: isActive ? 1 : 0.5
                    )
            )
            .cornerRadius(9)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LogRow

struct LogRow: View {
    let session: RunSession
    let vm: ReportViewModel
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(dotColor)
                    .frame(width: 5, height: 5)

                Text(session.startDate, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 10))
                    .foregroundColor(theme.textMid)
                    .frame(minWidth: 32, alignment: .leading)

                VStack(alignment: .leading, spacing: 0.5) {
                    Text("\(Int(session.duration / 60)) min")
                        .font(.system(size: 11))
                        .foregroundColor(theme.text)
                    let sub = vm.logSecondaryValue(session: session)
                    if !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 9))
                            .foregroundColor(theme.textDim)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
            }
            .padding(.vertical, 7)

            Rectangle()
                .fill(theme.accentDim)
                .frame(height: 0.5)
        }
    }

    private var dotColor: Color {
        if session.avgHR > 0 { return theme.bar[3] }
        return theme.bar[2]
    }
}
