import Charts
import SwiftUI

enum OverviewMode: String, CaseIterable, Identifiable {
    case perSession = "Per Session"
    case perDay = "Per Day"
    var id: String { rawValue }
}

struct StatsOverviewView: View {
    @Binding var user: Profile
    @Binding var tabSelection: Int

    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int? = nil
    @State private var overviewMode: OverviewMode = .perSession

    /// Returns the list of unique years from user sessions, sorted descending.
    var availableYears: [Int] {
        let years: Set<Int> = Set(user.sessions.map { Calendar.current.component(.year, from: $0.startTime) })
        return years.sorted(by: >)
    }

    /// Filters sessions by selected year and month (if any).
    var filteredSessions: [Session] {
        user.sessions.filter { (session: Session) -> Bool in
            Calendar.current.component(.year, from: session.startTime) == selectedYear &&
            (selectedMonth == nil || Calendar.current.component(.month, from: session.startTime) == selectedMonth)
        }
    }

    /// Aggregates sessions into daily summaries.
    var dailyAggregates: [AggregatedDay] {
        let grouped: [Date: [Session]] = Dictionary(grouping: filteredSessions) { session in
            Calendar.current.startOfDay(for: session.startTime)
        }
        return grouped.map { (date: Date, sessions: [Session]) -> AggregatedDay in
            AggregatedDay(
                date: date,
                sessionCount: sessions.count,
                totalPasses: sessions.reduce(0) { $0 + $1.passes.count },
                avgPasses: sessions.isEmpty ? 0 : Double(sessions.reduce(0) { $0 + $1.passes.count }) / Double(sessions.count),
                longestSession: sessions.map { $0.sessionLength.minute ?? 0 }.max() ?? 0,
                bestPass: sessions.flatMap { $0.passes.map { $0.pointsRaw } }.max() ?? 0.0,
                avgScore: getAverageScorePasses(passes: sessions.flatMap { $0.passes })
            )
        }.sorted { $0.date < $1.date }
    }

    struct AggregatedDay: Identifiable {
        let date: Date
        let sessionCount: Int
        let totalPasses: Int
        let avgPasses: Double
        let longestSession: Int
        let bestPass: Double
        let avgScore: Double
        var id: Date { date }
    }

    /// Returns the list of months for the selected year, sorted ascending.
    var monthsForSelectedYear: [Int] {
        let months: Set<Int> = Set(user.sessions.filter { Calendar.current.component(.year, from: $0.startTime) == selectedYear }
                                    .map { Calendar.current.component(.month, from: $0.startTime) })
        return months.sorted()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Overview Mode", selection: $overviewMode) {
                    ForEach(OverviewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 6)

                // Year Picker
                YearPickerView(availableYears: availableYears, selectedYear: selectedYear) { (year: Int) in
                    selectedYear = year
                    selectedMonth = nil
                }

                // Month Picker (optional)
                if !monthsForSelectedYear.isEmpty {
                    MonthPickerView(monthsForSelectedYear: monthsForSelectedYear, selectedMonth: selectedMonth, onSelect: { (month: Int?) in
                        selectedMonth = month
                    }, monthName: monthName(for:))
                }

                if (overviewMode == .perSession && filteredSessions.isEmpty) ||
                    (overviewMode == .perDay && dailyAggregates.isEmpty) {
                    Spacer()
                    VStack(spacing: 24) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.secondary)
                        Text("No ski sessions for this period!")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Stats Grid
                    SectionHeader("Quick Stats")
                    if overviewMode == .perSession {
                        StatsGrid(sessions: filteredSessions, mode: overviewMode)
                            .padding(.bottom, 8)
                            .id(overviewMode)
                    } else {
                        StatsGrid(dailyAggregates: dailyAggregates, mode: overviewMode)
                            .padding(.bottom, 8)
                            .id(overviewMode)
                    }

                    // Charts
                    SectionHeader("Session Overview")
                    if overviewMode == .perSession {
                        ChartSection(sessions: filteredSessions, mode: overviewMode)
                            .id(overviewMode)
                    } else {
                        ChartSection(dailyAggregates: dailyAggregates, mode: overviewMode)
                            .id(overviewMode)
                    }
                    Spacer(minLength: 10)
                }
            }
            .padding(.top, 10)
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
        }
    }

    // MARK: - Helper Methods

    /// Returns the localized month name for a given month number (1-12).
    func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Use standard month symbols or fallback abbreviated names
        let monthSymbols = formatter.monthSymbols ?? ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return monthSymbols[safe: month - 1] ?? "Month"
    }
}

// MARK: - Year Picker View
struct YearPickerView: View {
    let availableYears: [Int]
    let selectedYear: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableYears, id: \.self) { year in
                    Button(action: {
                        onSelect(year)
                    }) {
                        Text("\(year)")
                            .fontWeight(.semibold)
                            .foregroundColor(selectedYear == year ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedYear == year ? Color.accentColor : Color(.systemGray5))
                            .clipShape(Capsule())
                            .animation(.easeInOut, value: selectedYear)
                    }
                }
            }
            .padding(.horizontal, 6)
        }
    }
}

// MARK: - Month Picker View
struct MonthPickerView: View {
    let monthsForSelectedYear: [Int]
    let selectedMonth: Int?
    let onSelect: (Int?) -> Void
    let monthName: (Int) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { onSelect(nil) }) {
                    Text("All Months")
                        .fontWeight(selectedMonth == nil ? .bold : .regular)
                        .foregroundColor(selectedMonth == nil ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedMonth == nil ? Color.accentColor : Color(.systemGray5))
                        .clipShape(Capsule())
                }
                ForEach(monthsForSelectedYear, id: \.self) { month in
                    Button(action: { onSelect(month) }) {
                        Text(monthName(month))
                            .fontWeight(selectedMonth == month ? .bold : .regular)
                            .foregroundColor(selectedMonth == month ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedMonth == month ? Color.accentColor : Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 6)
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    var title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        HStack {
            Text(title)
                .font(.title3).bold()
            Spacer()
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}

// MARK: - Stats Grid
struct StatsGrid: View {
    let sessions: [Session]?
    let dailyAggregates: [StatsOverviewView.AggregatedDay]?
    let mode: OverviewMode

    init(sessions: [Session], mode: OverviewMode) {
        self.sessions = sessions
        self.dailyAggregates = nil
        self.mode = mode
    }

    init(dailyAggregates: [StatsOverviewView.AggregatedDay], mode: OverviewMode) {
        self.dailyAggregates = dailyAggregates
        self.sessions = nil
        self.mode = mode
    }

    /// Calculates total passes from sessions or aggregates.
    private var totalPasses: Int {
        if let sessions = sessions {
            return sessions.reduce(0) { $0 + $1.passes.count }
        } else if let aggregates = dailyAggregates {
            return aggregates.reduce(0) { $0 + $1.totalPasses }
        }
        return 0
    }

    /// Calculates average passes per session or day.
    private var avgPasses: Double {
        if let sessions = sessions {
            return sessions.isEmpty ? 0 : Double(totalPasses) / Double(sessions.count)
        } else if let aggregates = dailyAggregates {
            return aggregates.isEmpty ? 0 : aggregates.map { $0.avgPasses }.reduce(0, +) / Double(aggregates.count)
        }
        return 0
    }

    /// Finds the longest session duration in minutes.
    private var longestSession: Int {
        if let sessions = sessions {
            return sessions.map { $0.sessionLength.minute ?? 0 }.max() ?? 0
        } else if let aggregates = dailyAggregates {
            return aggregates.map { $0.longestSession }.max() ?? 0
        }
        return 0
    }

    /// Finds the weekday with the most sessions or aggregates.
    private var mostActiveDay: Int? {
        if let sessions = sessions {
            let dayGroups = Dictionary(grouping: sessions) { Calendar.current.component(.weekday, from: $0.startTime) }
            var maxKey: Int? = nil
            var maxCount = 0
            for (key, value) in dayGroups {
                if value.count > maxCount {
                    maxCount = value.count
                    maxKey = key
                }
            }
            return maxKey
        } else if let aggregates = dailyAggregates {
            let dayGroups = Dictionary(grouping: aggregates) { Calendar.current.component(.weekday, from: $0.date) }
            var maxKey: Int? = nil
            var maxTotal = 0
            for (key, value) in dayGroups {
                let sessionTotal = value.map { $0.sessionCount }.reduce(0, +)
                if sessionTotal > maxTotal {
                    maxTotal = sessionTotal
                    maxKey = key
                }
            }
            return maxKey
        }
        return nil
    }

    /// Finds the best pass score from sessions or aggregates.
    private var bestPass: Double {
        if let sessions = sessions {
            return sessions.flatMap { $0.passes.map { $0.pointsRaw } }.max() ?? 0.0
        } else if let aggregates = dailyAggregates {
            return aggregates.map { $0.bestPass }.max() ?? 0.0
        }
        return 0
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let sessions = sessions {
                StatCard(icon: "calendar", label: "Sessions", value: "\(sessions.count)")
                StatCard(icon: "skis", label: "Passes", value: "\(totalPasses)")
                StatCard(icon: "number", label: "Avg. Passes", value: String(format: "%.1f", avgPasses))
                StatCard(icon: "clock.arrow.circlepath", label: "Longest (min)", value: "\(longestSession)")
                StatCard(icon: "chart.bar.fill", label: "Best Pass", value: String(format: "%.1f", bestPass))
                if let weekday = mostActiveDay {
                    StatCard(icon: "star.circle.fill", label: "Most Active", value: weekdayName(weekday))
                }
            } else if let aggregates = dailyAggregates {
                StatCard(icon: "calendar", label: "Days", value: "\(aggregates.count)")
                let totalSessions = aggregates.map { $0.sessionCount }.reduce(0, +)
                StatCard(icon: "calendar.badge.plus", label: "Sessions", value: "\(totalSessions)")
                StatCard(icon: "skis", label: "Passes", value: "\(totalPasses)")
                StatCard(icon: "number", label: "Avg. Passes", value: String(format: "%.1f", avgPasses))
                StatCard(icon: "clock.arrow.circlepath", label: "Longest (min)", value: "\(longestSession)")
                StatCard(icon: "chart.bar.fill", label: "Best Pass", value: String(format: "%.1f", bestPass))
                if let weekday = mostActiveDay {
                    StatCard(icon: "star.circle.fill", label: "Most Active", value: weekdayName(weekday))
                }
            }
        }
    }

    /// Returns the localized weekday name for a given weekday number (1-7).
    func weekdayName(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.weekdaySymbols[safe: weekday - 1] ?? "Day"
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.accentColor)
                .shadow(radius: 1)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: .accentColor.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Chart Section
struct ChartSection: View {
    let sessions: [Session]?
    let dailyAggregates: [StatsOverviewView.AggregatedDay]?
    let mode: OverviewMode

    init(sessions: [Session], mode: OverviewMode) {
        self.sessions = sessions
        self.dailyAggregates = nil
        self.mode = mode
    }

    init(dailyAggregates: [StatsOverviewView.AggregatedDay], mode: OverviewMode) {
        self.dailyAggregates = dailyAggregates
        self.sessions = nil
        self.mode = mode
    }

    var body: some View {
        VStack(spacing: 18) {
            if let sessions = sessions {
                // Passes per Session Bar Chart
                Chart {
                    ForEach(sessions.sorted(by: { $0.startTime < $1.startTime }), id: \.id) { session in
                        // Use session's start time as unique session identifier for X-axis
                        BarMark(
                            x: .value("Session", session.startTime),
                            y: .value("Passes", session.passes.count)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .annotation(position: .top, alignment: .center) {
                            if session.passes.count > 0 {
                                Text("\(session.passes.count)")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                .frame(height: 160)
                .animation(.easeInOut, value: sessions.map { $0.id })
                .chartYAxisLabel(position: .trailing, alignment: .center) {
                    Text("Passes")
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    Text("Date")
                }

                // Average Score Line Chart
                Chart {
                    ForEach(sessions.sorted(by: { $0.startTime < $1.startTime }), id: \.id) { session in
                        let avgScore: Double = getAverageScorePasses(passes: session.passes)
                        // Use session's start time as unique session identifier for X-axis
                        LineMark(
                            x: .value("Session", session.startTime),
                            y: .value("Avg Score", avgScore)
                        )
                        PointMark(
                            x: .value("Session", session.startTime),
                            y: .value("Avg Score", avgScore)
                        )
                    }
                }
                .frame(height: 140)
                .animation(.easeInOut, value: sessions.map { $0.id })
                .chartYAxisLabel(position: .trailing, alignment: .center) {
                    Text("Average Score")
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    Text("Date")
                }
            } else if let aggregates = dailyAggregates {
                // Passes per Day Bar Chart
                Chart {
                    ForEach(aggregates, id: \.id) { day in
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Passes", day.totalPasses)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .annotation(position: .top, alignment: .center) {
                            if day.totalPasses > 0 {
                                Text("\(day.totalPasses)")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                .frame(height: 160)
                .animation(.easeInOut, value: aggregates.map { $0.id })
                .chartYAxisLabel(position: .trailing, alignment: .center) {
                    Text("Passes")
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    Text("Date")
                }

                // Average Score Line Chart per Day
                Chart {
                    ForEach(aggregates, id: \.id) { day in
                        LineMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Avg Score", day.avgScore)
                        )
                        PointMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Avg Score", day.avgScore)
                        )
                    }
                }
                .frame(height: 140)
                .animation(.easeInOut, value: aggregates.map { $0.id })
                .chartYAxisLabel(position: .trailing, alignment: .center) {
                    Text("Average Score")
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    Text("Date")
                }
            }
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - Utility Extensions

extension Collection {
    /// Safely returns the element at the specified index if it exists.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Helper Functions

/// Calculates the average score from an array of passes.
func getAverageScorePasses(passes: [Pass]) -> Double {
    let totalScore = passes.reduce(0.0) { $0 + Double($1.pointsRaw) }
    return passes.isEmpty ? 0 : totalScore / Double(passes.count)
}

/// Formats a number with specified fraction digits (default 1).
/// Useful to maintain consistent formatting across the project.
func formatNumber(_ value: Double, fractionDigits: Int = 1) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = fractionDigits
    formatter.maximumFractionDigits = fractionDigits
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

// Preview
// MARK: - Preview
#Preview {
    let newProfile = Profile(name: "Kaden", gender: .male, dateOfBirth: Date(), profilePicture: Data(), prefSpeed: 100, prefLength: 100)
    StatsOverviewView(user: .constant(newProfile), tabSelection: .constant(3))
}
