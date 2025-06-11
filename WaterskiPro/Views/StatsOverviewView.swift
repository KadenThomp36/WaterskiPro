import Charts
import SwiftUI

struct StatsOverviewView: View {
    @Binding var user: Profile
    @Binding var tabSelection: Int

    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int? = nil

    var availableYears: [Int] {
        let years = Set(user.sessions.map { Calendar.current.component(.year, from: $0.startTime) })
        return years.sorted(by: >)
    }

    var filteredSessions: [Session] {
        user.sessions.filter {
            Calendar.current.component(.year, from: $0.startTime) == selectedYear &&
            (selectedMonth == nil || Calendar.current.component(.month, from: $0.startTime) == selectedMonth)
        }
    }

    var monthsForSelectedYear: [Int] {
        let months = Set(user.sessions.filter { Calendar.current.component(.year, from: $0.startTime) == selectedYear }.map { Calendar.current.component(.month, from: $0.startTime) })
        return months.sorted()
    }

    var body: some View {
        VStack(spacing: 16) {
            // Year Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableYears, id: \.self) { year in
                        Button(action: {
                            selectedYear = year
                            selectedMonth = nil
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
            // Month Picker (optional)
            if !monthsForSelectedYear.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: { selectedMonth = nil }) {
                            Text("All Months")
                                .fontWeight(selectedMonth == nil ? .bold : .regular)
                                .foregroundColor(selectedMonth == nil ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedMonth == nil ? Color.accentColor : Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                        ForEach(monthsForSelectedYear, id: \.self) { month in
                            Button(action: { selectedMonth = month }) {
                                Text(monthName(for: month))
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

            if filteredSessions.isEmpty {
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
                StatsGrid(sessions: filteredSessions)
                    .padding(.bottom, 8)

                // Charts
                SectionHeader("Session Overview")
                ChartSection(sessions: filteredSessions)
                Spacer(minLength: 10)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
    }

    // MARK: - Helpers
    func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let monthSymbols = formatter.monthSymbols ?? ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return monthSymbols[safe: month - 1] ?? "Month"
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
    let sessions: [Session]
    var body: some View {
        let totalPasses = sessions.reduce(0) { $0 + $1.passes.count }
        let avgPasses = sessions.isEmpty ? 0 : Double(totalPasses) / Double(sessions.count)
        let longestSession = sessions.map { $0.sessionLength.minute ?? 0 }.max() ?? 0
        let dayGroups = Dictionary(grouping: sessions) { Calendar.current.component(.weekday, from: $0.startTime) }
        let mostActiveDay = dayGroups.max { $0.value.count < $1.value.count }?.key
        let bestPass = sessions.flatMap { $0.passes.map { $0.pointsRaw } }.max() ?? 0.0

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(icon: "calendar", label: "Sessions", value: "\(sessions.count)")
            StatCard(icon: "skis", label: "Passes", value: "\(totalPasses)")
            StatCard(icon: "number", label: "Avg. Passes", value: String(format: "%.1f", avgPasses))
            StatCard(icon: "clock.arrow.circlepath", label: "Longest (min)", value: "\(longestSession)")
            StatCard(icon: "chart.bar.fill", label: "Best Pass", value: String(format: "%.1f", bestPass))
            if let weekday = mostActiveDay {
                StatCard(icon: "star.circle.fill", label: "Most Active", value: weekdayName(weekday))
            }
        }
    }
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
    let sessions: [Session]
    var body: some View {
        VStack(spacing: 18) {
            // Passes per Session Bar Chart
            Chart {
                ForEach(sessions.sorted(by: { $0.startTime < $1.startTime }), id: \.id) { session in
                    BarMark(
                        x: .value("Date", session.startTime, unit: .day),
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
                    let avgScore = getAverageScorePasses(passes: session.passes)
                    LineMark(
                        x: .value("Date", session.startTime, unit: .day),
                        y: .value("Avg Score", avgScore)
                    )
                    PointMark(
                        x: .value("Date", session.startTime, unit: .day),
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
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - Utility
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

func getAverageScorePasses(passes: [Pass]) -> Double {
    let totalScore = passes.reduce(0.0) { $0 + Double($1.pointsRaw) }
    return passes.isEmpty ? 0 : totalScore / Double(passes.count)
}

// Preview
#Preview {
    let newProfile = Profile(name: "Kaden", gender: .male, dateOfBirth: Date(), profilePicture: Data(), prefSpeed: 100, prefLength: 100)
    StatsOverviewView(user: .constant(newProfile), tabSelection: .constant(3))
}
