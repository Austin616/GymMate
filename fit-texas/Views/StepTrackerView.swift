//
//  StepTrackerView.swift
//  fit-texas
//
//  Created by Claude Code
//

import SwiftUI
import HealthKit

struct StepTrackerView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var selectedDate = Date()
    @State private var selectedDaySteps: Int = 0
    @State private var hourlySteps: [HourlySteps] = []
    @State private var weeklySteps: [DaySteps] = []
    @State private var monthlyData: [Date: Int] = [:]
    @State private var dailyGoal: Int = 10000
    @State private var showGoalSheet: Bool = false
    @State private var newGoalText: String = ""
    @State private var isLoadingHourly: Bool = false
    @State private var isLoadingMonthly: Bool = false
    @State private var viewMode: StepViewMode = .day
    @AppStorage("stepDailyGoal") private var storedGoal: Int = 10000
    @Environment(\.presentationMode) var presentationMode
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var displaySteps: Int {
        isToday ? healthKitManager.todaySteps : selectedDaySteps
    }
    
    private var todayProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(displaySteps) / Double(dailyGoal), 1.0)
    }
    
    private var maxHourlySteps: Int {
        max(hourlySteps.map { $0.steps }.max() ?? 1, 1)
    }

    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // View Mode Selector (single segmented control)
                    Picker("View", selection: $viewMode) {
                        Text("Day").tag(StepViewMode.day)
                        Text("Week").tag(StepViewMode.week)
                        Text("Month").tag(StepViewMode.month)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewMode) { newMode in
                        if newMode == .month {
                            loadMonthData()
                        } else if newMode == .week {
                            loadWeeklyData()
                        }
                    }
                    
                    // Content based on view mode
                    switch viewMode {
                    case .day:
                        DayDetailContent(
                            selectedDate: $selectedDate,
                            displaySteps: displaySteps,
                            dailyGoal: dailyGoal,
                            todayProgress: todayProgress,
                            hourlySteps: hourlySteps,
                            maxHourlySteps: maxHourlySteps,
                            isLoading: isLoadingHourly,
                            onDateChange: { loadDataForDate() }
                        )
                        
                    case .week:
                        WeekViewContent(
                            weeklySteps: weeklySteps,
                            dailyGoal: dailyGoal,
                            selectedDate: selectedDate,
                            onDayTap: { daySteps in
                                selectedDate = daySteps.date
                                viewMode = .day
                                loadDataForDate()
                            }
                        )
                        
                    case .month:
                        MonthViewContent(
                            selectedDate: $selectedDate,
                            monthlyData: monthlyData,
                            dailyGoal: dailyGoal,
                            isLoading: isLoadingMonthly,
                            onMonthChange: { loadMonthData() },
                            onDayTap: { date in
                                selectedDate = date
                                viewMode = .day
                                loadDataForDate()
                            }
                        )
                    }
                    
                    // Quick Stats (always visible)
                    QuickStatsGrid(
                        steps: displaySteps,
                        goal: dailyGoal,
                        weeklySteps: weeklySteps
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 16)
            }
        .navigationTitle("Steps")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    newGoalText = "\(dailyGoal)"
                    showGoalSheet = true
                }) {
                    Image(systemName: "target")
                        .foregroundColor(.utOrange)
                }
            }
        }
        .sheet(isPresented: $showGoalSheet) {
            GoalSheetView(goalText: $newGoalText, onSave: {
                if let newGoal = Int(newGoalText), newGoal > 0 {
                    dailyGoal = newGoal
                    storedGoal = newGoal
                }
                showGoalSheet = false
            })
        }
        .onAppear {
            dailyGoal = storedGoal
            loadDataForDate()
            loadWeeklyData()
            if !healthKitManager.isAuthorized {
                healthKitManager.requestAuthorization()
            }
        }
    }
    
    private func loadDataForDate() {
        isLoadingHourly = true
        
        // Load hourly data for selected date
        healthKitManager.fetchHourlySteps(for: selectedDate) { steps in
            hourlySteps = steps
            isLoadingHourly = false
        }
        
        // Load steps for selected date if not today
        if !isToday {
            healthKitManager.fetchSteps(for: selectedDate) { steps in
                selectedDaySteps = steps
            }
        }
    }
    
    private func loadWeeklyData() {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: Date()) else { return }
        
        healthKitManager.fetchSteps(from: weekStart, to: Date()) { stepsByDate in
            var result: [DaySteps] = []
            
            for offset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: offset, to: weekStart) {
                    let dayStart = calendar.startOfDay(for: date)
                    let steps = stepsByDate[dayStart] ?? 0
                    
                    result.append(DaySteps(
                        date: date,
                        steps: steps,
                        dayLabel: formatDayLabel(date),
                        isToday: calendar.isDateInToday(date)
                    ))
                }
            }
            
            weeklySteps = result
        }
    }
    
    private func loadMonthData() {
        isLoadingMonthly = true
        
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else { return }
        
        healthKitManager.fetchSteps(from: monthInterval.start, to: monthInterval.end) { data in
            monthlyData = data
            isLoadingMonthly = false
        }
    }
    
    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let str = formatter.string(from: date)
        return String(str.prefix(3))
    }
}

// MARK: - View Mode

enum StepViewMode {
    case day, week, month
}

// MARK: - Day Detail Content

struct DayDetailContent: View {
    @Binding var selectedDate: Date
    let displaySteps: Int
    let dailyGoal: Int
    let todayProgress: Double
    let hourlySteps: [HourlySteps]
    let maxHourlySteps: Int
    let isLoading: Bool
    var onDateChange: () -> Void
    
    private var dateString: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }
    
    private var canGoForward: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Date Navigation
            HStack {
                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                        selectedDate = newDate
                        onDateChange()
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.utOrange)
                }
                
                Spacer()
                
                Text(dateString)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    if canGoForward, let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                        selectedDate = newDate
                        onDateChange()
                    }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(canGoForward ? .utOrange : .secondary.opacity(0.3))
                }
                .disabled(!canGoForward)
            }
            .padding(.horizontal)
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 18)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: todayProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: todayProgress)

                VStack(spacing: 4) {
                    Text("\(displaySteps)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("of \(dailyGoal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Message
            if todayProgress >= 1.0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Goal Achieved!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.15))
                .cornerRadius(12)
            }
            
            // Hourly Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Hourly Breakdown")
                    .font(.headline)
                    .padding(.horizontal)
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .frame(height: 150)
                } else if hourlySteps.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No step data")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .frame(height: 150)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 6) {
                            ForEach(hourlySteps) { hourData in
                                VStack(spacing: 4) {
                                    // Bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            hourData.steps > 0 ?
                                            LinearGradient(
                                                colors: [Color.green, Color.mint],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            ) :
                                            LinearGradient(
                                                colors: [Color(.systemGray5), Color(.systemGray6)],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                        .frame(width: 18, height: barHeight(for: hourData.steps))
                                    
                                    // Hour label
                                    Text(hourData.shortLabel)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 140)
                    }
                }
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    private func barHeight(for steps: Int) -> CGFloat {
        guard maxHourlySteps > 0 else { return 4 }
        let height = CGFloat(steps) / CGFloat(maxHourlySteps) * 100
        return max(height, 4)
    }
}

// MARK: - Week View Content

struct WeekViewContent: View {
    let weeklySteps: [DaySteps]
    let dailyGoal: Int
    let selectedDate: Date
    let onDayTap: (DaySteps) -> Void
    
    private var maxSteps: Int {
        max(weeklySteps.map { $0.steps }.max() ?? dailyGoal, dailyGoal)
    }
    
    private var weekTotal: Int {
        weeklySteps.reduce(0) { $0 + $1.steps }
    }
    
    private var weekAverage: Int {
        guard !weeklySteps.isEmpty else { return 0 }
        return weekTotal / weeklySteps.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Week Summary
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(formatNumber(weekTotal))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text(formatNumber(weekAverage))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Daily Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Weekly Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text("Tap a day to see details")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklySteps) { dayStep in
                        Button(action: { onDayTap(dayStep) }) {
                            VStack(spacing: 8) {
                                // Steps label
                                Text(formatNumber(dayStep.steps))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                // Bar
                                VStack {
                                    Spacer()
                                    
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            dayStep.isToday ?
                                            LinearGradient(
                                                colors: [Color.green, Color.mint],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            ) :
                                            dayStep.steps >= dailyGoal ?
                                            LinearGradient(
                                                colors: [Color.green.opacity(0.7), Color.mint.opacity(0.7)],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            ) :
                                            LinearGradient(
                                                colors: [Color(.systemGray4), Color(.systemGray5)],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                        .frame(height: barHeight(for: dayStep.steps))
                                }
                                .frame(height: 120)
                                
                                // Day Label
                                Text(dayStep.dayLabel)
                                    .font(.caption)
                                    .fontWeight(dayStep.isToday ? .bold : .regular)
                                    .foregroundColor(dayStep.isToday ? .green : .primary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                // Goal reference
                HStack {
                    Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 20, height: 2)
                    Text("Daily Goal: \(dailyGoal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    private func barHeight(for steps: Int) -> CGFloat {
        guard maxSteps > 0 else { return 0 }
        return CGFloat(steps) / CGFloat(maxSteps) * 120
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

// MARK: - Month View Content

struct MonthViewContent: View {
    @Binding var selectedDate: Date
    let monthlyData: [Date: Int]
    let dailyGoal: Int
    let isLoading: Bool
    var onMonthChange: () -> Void
    let onDayTap: (Date) -> Void
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else { return [] }
        
        var dates: [Date] = []
        var date = monthInterval.start
        
        while date < monthInterval.end {
            dates.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }
        
        return dates
    }
    
    private var monthTotal: Int {
        monthlyData.values.reduce(0, +)
    }
    
    private var daysWithGoal: Int {
        monthlyData.values.filter { $0 >= dailyGoal }.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Month Navigation
            HStack {
                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
                        selectedDate = newDate
                        onMonthChange()
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.utOrange)
                }
                
                Spacer()
                
                Text(monthString)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
                        selectedDate = newDate
                        onMonthChange()
                    }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.utOrange)
                }
            }
            .padding(.horizontal)
            
            // Month Summary
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(formatNumber(monthTotal))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Steps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(daysWithGoal)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Goals Hit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 250)
            } else {
                // Calendar Grid
                VStack(spacing: 8) {
                    Text("Tap a day to see details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                        // Day headers
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                            Text(day)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(height: 20)
                        }
                        
                        // Leading empty cells
                        let firstWeekday = Calendar.current.component(.weekday, from: daysInMonth.first ?? Date())
                        ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                            Color.clear
                                .frame(height: 40)
                        }
                        
                        // Day cells
                        ForEach(daysInMonth, id: \.self) { date in
                            let steps = monthlyData[Calendar.current.startOfDay(for: date)] ?? 0
                            let progress = Double(steps) / Double(dailyGoal)
                            let isToday = Calendar.current.isDateInToday(date)
                            
                            Button(action: { onDayTap(date) }) {
                                MonthDayCell(
                                    date: date,
                                    steps: steps,
                                    progress: progress,
                                    isToday: isToday
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Legend
                HStack(spacing: 16) {
                    LegendItem(color: .green.opacity(0.3), label: "< 50%")
                    LegendItem(color: .green.opacity(0.6), label: "50-99%")
                    LegendItem(color: .green, label: "100%+")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000.0)
        } else if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

// MARK: - Month Day Cell

struct MonthDayCell: View {
    let date: Date
    let steps: Int
    let progress: Double
    let isToday: Bool
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    private var backgroundColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.5 {
            return .green.opacity(0.6)
        } else if progress > 0 {
            return .green.opacity(0.3)
        }
        return Color(.systemGray6)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
            
            Text("\(dayNumber)")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(progress >= 0.5 ? .white : .primary)
        }
        .frame(height: 40)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? Color.utOrange : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
        }
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    let steps: Int
    let goal: Int
    let weeklySteps: [DaySteps]
    
    private var weeklyAverage: Int {
        guard !weeklySteps.isEmpty else { return 0 }
        let total = weeklySteps.reduce(0) { $0 + $1.steps }
        return total / weeklySteps.count
    }
    
    private var goalStreak: Int {
        var streak = 0
        let sortedDays = weeklySteps.sorted { $0.date > $1.date }
        
        for dayStep in sortedDays {
            if dayStep.steps >= goal {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    // Approximate distance (0.8m per step)
    private var distance: Double {
        Double(steps) * 0.0008
    }
    
    // Approximate calories (0.04 cal per step)
    private var calories: Int {
        Int(Double(steps) * 0.04)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                QuickStatCard(
                    title: "Distance",
                    value: String(format: "%.1f", distance),
                    subtitle: "km today",
                    icon: "location.fill",
                    color: .blue
                )
                
                QuickStatCard(
                    title: "Calories",
                    value: "\(calories)",
                    subtitle: "kcal burned",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            
            HStack(spacing: 12) {
                QuickStatCard(
                    title: "Weekly Avg",
                    value: formatNumber(weeklyAverage),
                    subtitle: "steps/day",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
                
                QuickStatCard(
                    title: "Goal Streak",
                    value: "\(goalStreak)",
                    subtitle: goalStreak == 1 ? "day" : "days",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

// MARK: - Day Steps Model

struct DaySteps: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    let dayLabel: String
    let isToday: Bool
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Goal Sheet View

struct GoalSheetView: View {
    @Binding var goalText: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Set Daily Step Goal")
                        .font(.title2.weight(.bold))

                    Text("Choose a daily step target")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                HStack {
                    TextField("10000", text: $goalText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 48, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text("steps")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)

                // Quick Presets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach([5000, 8000, 10000, 12000, 15000], id: \.self) { preset in
                                Button(action: {
                                    goalText = "\(preset)"
                                }) {
                                    Text("\(preset)")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(goalText == "\(preset)" ? .white : .utOrange)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(goalText == "\(preset)" ? Color.utOrange : Color.utOrange.opacity(0.1))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button(action: onSave) {
                    Text("Save Goal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.utOrange)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StepTrackerView()
    }
}
