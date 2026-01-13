//
//  ProfileView.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var historyManager = WorkoutHistoryManager.shared
    @StateObject private var statsManager = StatsManager()
    @StateObject private var socialManager = SocialManager.shared
    @StateObject private var gamificationManager = GamificationManager.shared
    @State private var showSettings = false
    @State private var selectedDate = Date()
    @State private var statsLoaded = false
    @State private var showAchievements = false
    @State private var showChallenges = false
    @State private var showLeaderboard = false

    var body: some View {
        VStack(spacing: 0) {
                CustomTabHeader(
                    title: "Profile",
                    trailingButton: AnyView(
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.utOrange)
                                .font(.title3)
                        }
                    )
                )

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header with Level
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.utOrange, Color.utOrange.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text((socialManager.currentUserProfile?.displayName.prefix(1).uppercased()) ?? (authManager.currentUser?.email?.prefix(1).uppercased()) ?? "U")
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: Color.utOrange.opacity(0.3), radius: 12, x: 0, y: 4)
                                
                                // Level Badge
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .frame(width: 36, height: 36)
                                    
                                    Circle()
                                        .fill(Color.utOrange)
                                        .frame(width: 30, height: 30)
                                    
                                    Text("\(gamificationManager.currentLevel)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 4, y: 4)
                            }

                            VStack(spacing: 4) {
                                Text(socialManager.currentUserProfile?.displayName ?? authManager.currentUser?.displayName ?? "User")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if let username = socialManager.currentUserProfile?.username {
                                    Text("@\(username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(authManager.currentUser?.email ?? "user@example.com")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Level & XP Progress
                            XPProgressCard(
                                level: gamificationManager.currentLevel,
                                totalXP: gamificationManager.totalXP
                            )
                            .padding(.horizontal)
                        }
                        .padding(.top, 20)

                    // Calendar Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout Calendar")
                            .font(.headline)
                            .padding(.horizontal)

                        WorkoutCalendarView(
                            selectedDate: $selectedDate,
                            workouts: historyManager.savedWorkouts,
                            historyManager: historyManager
                        )
                        .padding(.horizontal, 8)
                    }

                    // Gamification Quick Links
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            GamificationLinkCard(
                                title: "Achievements",
                                value: "\(gamificationManager.unlockedAchievements.count)/\(PredefinedAchievements.all.count)",
                                icon: "trophy.fill",
                                color: .yellow
                            ) {
                                showAchievements = true
                            }
                            
                            GamificationLinkCard(
                                title: "Challenges",
                                value: "\(gamificationManager.activeChallenges.count) active",
                                icon: "target",
                                color: .green
                            ) {
                                showChallenges = true
                            }
                            
                            GamificationLinkCard(
                                title: "Leaderboard",
                                value: "\(socialManager.friends.count) friends",
                                icon: "chart.bar.fill",
                                color: .blue
                            ) {
                                showLeaderboard = true
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recent Achievements
                    if !gamificationManager.unlockedAchievements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Achievements")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("See All") {
                                    showAchievements = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.utOrange)
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(gamificationManager.unlockedAchievements.suffix(5).reversed()) { userAchievement in
                                        if let achievement = PredefinedAchievements.achievement(byId: userAchievement.achievementId) {
                                            RecentAchievementBadge(achievement: achievement)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Stats Cards
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stats")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                StatCardProfile(title: "Workouts", value: "\(statsManager.stats.totalWorkouts)", icon: "figure.strengthtraining.traditional")
                                StatCardProfile(title: "Streak", value: "\(statsManager.stats.currentStreak)", icon: "flame.fill")
                            }

                            HStack(spacing: 12) {
                                StatCardProfile(title: "Volume", value: "\(statsManager.formattedVolume()) kg", icon: "scalemass.fill")
                                StatCardProfile(title: "This Week", value: "\(statsManager.stats.workoutsThisWeek)", icon: "calendar")
                            }
                        }
                        .padding(.horizontal)
                    }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .background(
                Group {
                    NavigationLink(destination: SettingsView().environmentObject(authManager), isActive: $showSettings) {
                        EmptyView()
                    }
                    NavigationLink(destination: AchievementsView(), isActive: $showAchievements) {
                        EmptyView()
                    }
                    NavigationLink(destination: ChallengesView(), isActive: $showChallenges) {
                        EmptyView()
                    }
                    NavigationLink(destination: LeaderboardView(), isActive: $showLeaderboard) {
                        EmptyView()
                    }
                }
                .hidden()
            )
            .onAppear {
                if !statsLoaded {
                    print("📊 [PROFILE] Loading stats...")
                    statsManager.calculateStats(from: historyManager.savedWorkouts)
                    statsLoaded = true
                }
            }
            .onChange(of: historyManager.savedWorkouts) { newWorkouts in
                print("📊 [PROFILE] Workouts changed, recalculating stats...")
                statsManager.calculateStats(from: newWorkouts)
            }
    }
}

struct WorkoutCalendarView: View {
    @Binding var selectedDate: Date
    let workouts: [SavedWorkout]
    @ObservedObject var historyManager: WorkoutHistoryManager

    private func hasWorkout(on date: Date) -> Bool {
        workouts.contains { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: date)
        }
    }

    var body: some View {
        NavigationCalendarView(
            selectedDate: $selectedDate,
            hasWorkout: hasWorkout,
            historyManager: historyManager
        )
    }
}

struct NavigationCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth = Date()
    let hasWorkout: (Date) -> Bool
    @ObservedObject var historyManager: WorkoutHistoryManager

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var dates: [Date] = []
        var date = monthFirstWeek.start

        while date < monthInterval.end {
            dates.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }

        return dates
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month/Year Header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.utOrange)
                }

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.utOrange)
                }
            }
            .padding(.horizontal)

            // Days of Week
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    NavigationLink(destination: DayDetailView(
                        selectedDate: date,
                        historyManager: historyManager
                    )) {
                        CalendarDayCell(
                            date: date,
                            selectedDate: selectedDate,
                            currentMonth: currentMonth,
                            hasWorkout: hasWorkout(date)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    private func previousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = newMonth
    }

    private func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = newMonth
    }
}

struct CalendarDayCell: View {
    let date: Date
    let selectedDate: Date
    let currentMonth: Date
    let hasWorkout: Bool

    private let calendar = Calendar.current

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(
                    isToday ? .utOrange :
                    isInCurrentMonth ? .primary : .secondary
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .stroke(isToday ? Color.utOrange : Color.clear, lineWidth: 2)
                )

            // Workout indicator dot
            Circle()
                .fill(hasWorkout ? Color.utOrange : Color.clear)
                .frame(width: 4, height: 4)
        }
        .opacity(isInCurrentMonth ? 1.0 : 0.4)
    }
}

struct DayDetailView: View {
    let selectedDate: Date
    @ObservedObject var historyManager: WorkoutHistoryManager
    @Environment(\.presentationMode) var presentationMode

    private var workoutsForDay: [SavedWorkout] {
        historyManager.savedWorkouts.filter { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: selectedDate)
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomTabHeader(
                title: dateString,
                leadingButton: AnyView(
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body)
                                .fontWeight(.semibold)
                            Text("Back")
                        }
                        .foregroundColor(.utOrange)
                    }
                ),
                isSubScreen: true
            )

            if workoutsForDay.isEmpty {
                // Empty State
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("No workouts on this day")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            } else {
                // Workouts List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(workoutsForDay) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                WorkoutHistoryCard(workout: workout)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct StatCardProfile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.utOrange)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var dates: [Date] = []
        var date = monthFirstWeek.start

        while date < monthInterval.end {
            dates.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }

        return dates
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month/Year Header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.utOrange)
                }

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.utOrange)
                }
            }
            .padding(.horizontal)

            // Days of Week
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        selectedDate: $selectedDate,
                        currentMonth: currentMonth
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    private func previousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = newMonth
    }

    private func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = newMonth
    }
}

struct CalendarDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let currentMonth: Date

    private let calendar = Calendar.current

    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    var body: some View {
        Button(action: {
            selectedDate = date
        }) {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(
                    isSelected ? .white :
                    isToday ? .utOrange :
                    isInCurrentMonth ? .primary : .secondary
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.utOrange : Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(isToday && !isSelected ? Color.utOrange : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .opacity(isInCurrentMonth ? 1.0 : 0.4)
    }
}

struct WorkoutHistoryCard: View {
    let workout: SavedWorkout

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.utOrange.opacity(0.15), Color.utOrange.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Stats
            HStack(spacing: 0) {
                StatItemCompact(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(workout.exercises.count)",
                    label: "exercises"
                )

                Divider()
                    .frame(height: 30)

                StatItemCompact(
                    icon: "number.circle.fill",
                    value: "\(workout.totalSets)",
                    label: "sets"
                )

                Divider()
                    .frame(height: 30)

                StatItemCompact(
                    icon: "scalemass.fill",
                    value: "\(Int(workout.totalVolume))",
                    label: "kg"
                )
            }
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StatItemCompact: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.utOrange)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - XP Progress Card

struct XPProgressCard: View {
    let level: Int
    let totalXP: Int
    
    private var levelProgress: (current: Int, required: Int, percentage: Double) {
        LevelSystem.xpProgressInLevel(totalXP)
    }
    
    private var levelTitle: String {
        LevelSystem.levelTitle(for: level)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Level \(level)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(levelTitle)
                        .font(.caption)
                        .foregroundColor(.utOrange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalXP) XP")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("\(levelProgress.current)/\(levelProgress.required) to next")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.utOrange, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * levelProgress.percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Gamification Link Card

struct GamificationLinkCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Achievement Badge

struct RecentAchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.utOrange)
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.iconName)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            Text(achievement.name)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(WorkoutTimerManager.shared)
}
