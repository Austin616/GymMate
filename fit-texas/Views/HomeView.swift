//
//  HomeView.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var historyManager: WorkoutHistoryManager
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var gamificationManager = GamificationManager.shared
    @StateObject private var socialManager = SocialManager.shared

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    private var userName: String {
        authManager.currentUser?.displayName?.components(separatedBy: " ").first ?? "Champion"
    }

    private var workoutStreak: Int {
        let workouts = historyManager.savedWorkouts.sorted { $0.date > $1.date }
        guard !workouts.isEmpty else { return 0 }

        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        for workout in workouts {
            let workoutDate = Calendar.current.startOfDay(for: workout.date)
            let daysDifference = Calendar.current.dateComponents([.day], from: workoutDate, to: currentDate).day ?? 0

            if daysDifference == streak {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if daysDifference > streak {
                break
            }
        }

        return streak
    }

    private var thisWeekWorkouts: [SavedWorkout] {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

        return historyManager.savedWorkouts.filter { $0.date >= weekAgo }
    }

    private var thisWeekVolume: Double {
        thisWeekWorkouts.reduce(0.0) { $0 + $1.totalVolume }
    }

    private var lastWorkout: SavedWorkout? {
        historyManager.savedWorkouts.sorted { $0.date > $1.date }.first
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                CustomTabHeader(title: "Home")

                    VStack(spacing: 20) {
                        // Welcome Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text(greeting)
                                .font(.title3)
                                .foregroundColor(.secondary)

                            Text("\(userName)!")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)

                            if historyManager.hasDraft {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Workout in progress")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [Color.utOrange.opacity(0.1), Color.utOrange.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // XP/Level Card
                        HStack(spacing: 16) {
                            // Level Badge
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.utOrange, .orange],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 50, height: 50)
                                    
                                    Text("\(gamificationManager.currentLevel)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                Text("Level")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // XP Progress
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(LevelSystem.levelTitle(for: gamificationManager.currentLevel))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(gamificationManager.totalXP) XP")
                                        .font(.subheadline)
                                        .foregroundColor(.utOrange)
                                }
                                
                                let progress = LevelSystem.xpProgressInLevel(gamificationManager.totalXP)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(.systemGray5))
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.utOrange)
                                            .frame(width: geometry.size.width * progress.percentage, height: 8)
                                    }
                                }
                                .frame(height: 8)
                                
                                Text("\(progress.current)/\(progress.required) XP to Level \(gamificationManager.currentLevel + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        // Stats Grid
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                // Streak Card
                                StatCardView(
                                    icon: "flame.fill",
                                    title: "Day Streak",
                                    value: "\(workoutStreak)",
                                    color: .orange,
                                    subtitle: workoutStreak == 1 ? "day" : "days"
                                )

                                // Steps Card - Tappable
                                NavigationLink(destination: StepTrackerView()) {
                                    StatCardView(
                                        icon: "figure.walk",
                                        title: "Steps Today",
                                        value: formatNumber(healthKitManager.todaySteps),
                                        color: .green,
                                        subtitle: "steps"
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            HStack(spacing: 16) {
                                // This Week Workouts
                                StatCardView(
                                    icon: "calendar",
                                    title: "This Week",
                                    value: "\(thisWeekWorkouts.count)",
                                    color: .blue,
                                    subtitle: thisWeekWorkouts.count == 1 ? "workout" : "workouts"
                                )

                                // Total Volume This Week
                                StatCardView(
                                    icon: "scalemass.fill",
                                    title: "Volume",
                                    value: formatNumber(Int(thisWeekVolume)),
                                    color: .purple,
                                    subtitle: "lbs this week"
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // Active Challenge Preview
                        if let activeChallenge = gamificationManager.activeChallenges.first {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("Active Challenge", systemImage: "target")
                                        .font(.headline)
                                        .foregroundColor(.utOrange)
                                    
                                    Spacer()
                                    
                                    NavigationLink(destination: ChallengesView()) {
                                        Text("See All")
                                            .font(.caption)
                                            .foregroundColor(.utOrange)
                                    }
                                }
                                
                                ChallengePreviewCard(challenge: activeChallenge)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Last Workout Card - Clickable
                        if let lastWorkout = lastWorkout {
                            NavigationLink(destination: WorkoutDetailView(workout: lastWorkout)) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Label("Last Workout", systemImage: "clock.fill")
                                            .font(.headline)
                                            .foregroundColor(.utOrange)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(lastWorkout.name)
                                            .font(.title3.weight(.semibold))
                                            .foregroundColor(.primary)

                                        HStack(spacing: 16) {
                                            Label("\(lastWorkout.exercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            Label("\(lastWorkout.totalSets) sets", systemImage: "number.circle.fill")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }

                                        Text(timeAgo(from: lastWorkout.date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 4)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color(.systemGray6))
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.bottom, 20)
                }
            .onAppear {
                if !healthKitManager.isAuthorized {
                    healthKitManager.requestAuthorization()
                }
                healthKitManager.startObservingSteps()
            }
        }
        .navigationBarHidden(true)
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Stat Card View

struct StatCardView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
        .environmentObject(WorkoutTimerManager.shared)
        .environmentObject(WorkoutHistoryManager.shared)
}
