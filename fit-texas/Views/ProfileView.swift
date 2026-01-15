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
    @StateObject private var feedManager = FeedManager.shared
    
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var selectedTab = 0
    @State private var showFollowers = false
    @State private var showFollowing = false
    @State private var showAchievements = false
    @State private var showLeaderboard = false
    @State private var statsLoaded = false
    @State private var userPosts: [FeedPost] = []
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Header
                profileHeader
                
                // Stats Row (Posts, Followers, Following)
                statsRow
                    .padding(.top, 16)
                
                // Bio & Level
                bioSection
                    .padding(.top, 12)
                
                // Action Buttons
                actionButtons
                    .padding(.top, 16)
                    .padding(.horizontal)
                
                // Currently Working Out Indicator
                if historyManager.hasDraft {
                    workingOutBanner
                        .padding(.top, 16)
                        .padding(.horizontal)
                }
                
                // Content Tabs
                contentTabs
                    .padding(.top, 20)
                
                // Tab Content
                tabContent
                    .padding(.top, 8)
            }
            .padding(.bottom, 100)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.primary)
                }
            }
        }
        .background(
            Group {
                NavigationLink(destination: SettingsView().environmentObject(authManager), isActive: $showSettings) {
                    EmptyView()
                }
                NavigationLink(destination: AchievementsView(), isActive: $showAchievements) {
                    EmptyView()
                }
                NavigationLink(destination: LeaderboardView(), isActive: $showLeaderboard) {
                    EmptyView()
                }
                NavigationLink(destination: FollowListView(userId: socialManager.currentUserProfile?.id ?? "", mode: .followers), isActive: $showFollowers) {
                    EmptyView()
                }
                NavigationLink(destination: FollowListView(userId: socialManager.currentUserProfile?.id ?? "", mode: .following), isActive: $showFollowing) {
                    EmptyView()
                }
            }
            .hidden()
        )
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet()
        }
        .onAppear {
            if !statsLoaded {
                statsManager.calculateStats(from: historyManager.savedWorkouts)
                statsLoaded = true
                loadUserPosts()
            }
        }
        .onChange(of: historyManager.savedWorkouts) { newWorkouts in
            statsManager.calculateStats(from: newWorkouts)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.utOrange, Color.utOrange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        Text((socialManager.currentUserProfile?.displayName.prefix(1).uppercased()) ?? "U")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                // Level Badge
                ZStack {
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .fill(Color.utOrange)
                        .frame(width: 26, height: 26)
                    
                    Text("\(gamificationManager.currentLevel)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 4, y: 4)
            }
            
            Text(socialManager.currentUserProfile?.displayName ?? authManager.currentUser?.displayName ?? "User")
                .font(.title3)
                .fontWeight(.bold)
            
            if let username = socialManager.currentUserProfile?.username {
                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 0) {
            ProfileStatButton(
                value: "\(socialManager.currentUserProfile?.postsCount ?? userPosts.count)",
                label: "Posts"
            ) {
                selectedTab = 0
            }
            
            ProfileStatButton(
                value: "\(socialManager.currentUserProfile?.followersCount ?? 0)",
                label: "Followers"
            ) {
                showFollowers = true
            }
            
            ProfileStatButton(
                value: "\(socialManager.currentUserProfile?.followingCount ?? 0)",
                label: "Following"
            ) {
                showFollowing = true
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Bio Section
    
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let bio = socialManager.currentUserProfile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            
            // Level & XP
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.utOrange)
                    .font(.caption)
                
                Text("Level \(gamificationManager.currentLevel)")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("\(gamificationManager.totalXP) XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(LevelSystem.levelTitle(for: gamificationManager.currentLevel))
                    .font(.caption)
                    .foregroundColor(.utOrange)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: { showEditProfile = true }) {
                Text("Edit Profile")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            Button(action: { showLeaderboard = true }) {
                Image(systemName: "chart.bar.fill")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 32)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            Button(action: { showAchievements = true }) {
                Image(systemName: "trophy.fill")
                    .font(.subheadline)
                    .foregroundColor(.utOrange)
                    .frame(width: 36, height: 32)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Working Out Banner
    
    private var workingOutBanner: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.4), lineWidth: 4)
                )
            
            Text("Currently Working Out")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Image(systemName: "figure.strengthtraining.traditional")
                .foregroundColor(.utOrange)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Content Tabs
    
    private var contentTabs: some View {
        HStack(spacing: 0) {
            ProfileTabButton(icon: "square.grid.3x3.fill", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            ProfileTabButton(icon: "calendar", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            ProfileTabButton(icon: "chart.line.uptrend.xyaxis", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .overlay(
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5),
            alignment: .top
        )
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            workoutGridView
        case 1:
            calendarView
        case 2:
            statsDetailView
        default:
            EmptyView()
        }
    }
    
    // MARK: - Workout Grid View
    
    private var workoutGridView: some View {
        Group {
            if userPosts.isEmpty && historyManager.savedWorkouts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "camera")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Share Your First Workout")
                        .font(.headline)
                    
                    Text("When you share workouts, they'll appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 60)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 2) {
                    ForEach(historyManager.savedWorkouts.prefix(30)) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            WorkoutGridCell(workout: workout)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Calendar View
    
    private var calendarView: some View {
        WorkoutCalendarView(
            selectedDate: .constant(Date()),
            workouts: historyManager.savedWorkouts,
            historyManager: historyManager
        )
        .padding(.horizontal)
    }
    
    // MARK: - Stats Detail View
    
    private var statsDetailView: some View {
        VStack(spacing: 16) {
            // Main Stats
            HStack(spacing: 12) {
                StatCardProfile(title: "Total Workouts", value: "\(statsManager.stats.totalWorkouts)", icon: "figure.strengthtraining.traditional")
                StatCardProfile(title: "Current Streak", value: "\(statsManager.stats.currentStreak)", icon: "flame.fill")
            }
            
            HStack(spacing: 12) {
                StatCardProfile(title: "Total Volume", value: "\(statsManager.formattedVolume()) kg", icon: "scalemass.fill")
                StatCardProfile(title: "This Week", value: "\(statsManager.stats.workoutsThisWeek)", icon: "calendar")
            }
            
            HStack(spacing: 12) {
                StatCardProfile(title: "Longest Streak", value: "\(statsManager.stats.longestStreak)", icon: "flame.circle.fill")
                StatCardProfile(title: "Achievements", value: "\(gamificationManager.unlockedAchievements.count)", icon: "trophy.fill")
            }
        }
        .padding(.horizontal)
    }
    
    private func loadUserPosts() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Task {
            userPosts = await feedManager.fetchUserPosts(userId: userId)
        }
    }
}

// MARK: - Profile Stat Button

struct ProfileStatButton: View {
    let value: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Tab Button

struct ProfileTabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(
                Rectangle()
                    .fill(isSelected ? Color.primary : Color.clear)
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Workout Grid Cell

struct WorkoutGridCell: View {
    let workout: SavedWorkout
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.utOrange.opacity(0.3), Color.utOrange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 4) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(.utOrange)
                
                Text("\(workout.exercises.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("exercises")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .aspectRatio(1, contentMode: .fill)
    }
}

// MARK: - Follow List View

struct FollowListView: View {
    let userId: String
    let mode: FollowMode
    
    @StateObject private var socialManager = SocialManager.shared
    @State private var users: [UserProfile] = []
    @State private var isLoading = true
    
    enum FollowMode {
        case followers
        case following
        
        var title: String {
            switch self {
            case .followers: return "Followers"
            case .following: return "Following"
            }
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if users.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: mode == .followers ? "person.2" : "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text(mode == .followers ? "No Followers Yet" : "Not Following Anyone")
                        .font(.headline)
                    
                    Spacer()
                }
            } else {
                List(users) { user in
                    NavigationLink(destination: UserProfileView(userId: user.id)) {
                        FollowUserRow(user: user)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadUsers()
        }
    }
    
    private func loadUsers() async {
        isLoading = true
        
        switch mode {
        case .followers:
            users = await socialManager.getFollowers(for: userId)
        case .following:
            users = await socialManager.getFollowing(for: userId)
        }
        
        isLoading = false
    }
}

// MARK: - Follow User Row

struct FollowUserRow: View {
    let user: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.utOrange, Color.utOrange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(user.displayName.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if user.isCurrentlyWorkingOut {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Working Out")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - Supporting Views

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

            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

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
        Group {
            if workoutsForDay.isEmpty {
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
        .navigationTitle(dateString)
        .navigationBarTitleDisplayMode(.inline)
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

struct WorkoutHistoryCard: View {
    let workout: SavedWorkout

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }

    var body: some View {
        VStack(spacing: 0) {
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

            HStack(spacing: 0) {
                StatItemCompact(icon: "figure.strengthtraining.traditional", value: "\(workout.exercises.count)", label: "exercises")
                Divider().frame(height: 30)
                StatItemCompact(icon: "number.circle.fill", value: "\(workout.totalSets)", label: "sets")
                Divider().frame(height: 30)
                StatItemCompact(icon: "scalemass.fill", value: "\(Int(workout.totalVolume))", label: "kg")
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

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthManager())
            .environmentObject(WorkoutTimerManager.shared)
    }
}
