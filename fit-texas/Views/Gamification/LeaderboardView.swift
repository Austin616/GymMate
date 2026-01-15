//
//  LeaderboardView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI
import FirebaseFirestore

struct LeaderboardView: View {
    @StateObject private var socialManager = SocialManager.shared
    
    @State private var selectedMetric: LeaderboardMetric = .level
    @State private var leaderboardEntries: [LeaderboardStats] = []
    @State private var isLoading = true
    @State private var showFriendsOnly = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Global/Friends Toggle
            HStack {
                Text("Show:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $showFriendsOnly) {
                    Text("Global").tag(false)
                    Text("Friends").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Metric Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LeaderboardMetric.allCases, id: \.self) { metric in
                        LeaderboardMetricChip(
                            metric: metric,
                            isSelected: selectedMetric == metric,
                            action: {
                                selectedMetric = metric
                                Task { await loadLeaderboard() }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if leaderboardEntries.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: showFriendsOnly ? "person.2.slash" : "chart.bar")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text(showFriendsOnly ? "No Friends Yet" : "No Users Found")
                        .font(.headline)
                    
                    Text(showFriendsOnly ? "Add friends to compete!" : "Be the first to join!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Top 3 Podium
                        if leaderboardEntries.count >= 3 {
                            LeaderboardPodiumView(entries: Array(leaderboardEntries.prefix(3)), metric: selectedMetric)
                                .padding(.vertical, 20)
                        }
                        
                        // Rest of Leaderboard
                        VStack(spacing: 8) {
                            ForEach(Array(leaderboardEntries.enumerated()), id: \.element.id) { index, entry in
                                if index >= 3 {
                                    LeaderboardRowView(entry: entry, rank: index + 1, metric: selectedMetric)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
                .refreshable {
                    await loadLeaderboard()
                }
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: showFriendsOnly) { _ in
            Task { await loadLeaderboard() }
        }
        .task {
            await loadLeaderboard()
        }
    }
    
    private func loadLeaderboard() async {
        isLoading = true
        
        let db = Firestore.firestore()
        var stats: [UserStats] = []
        
        if showFriendsOnly {
            // Friends only
            var userIds = socialManager.getFriendIds()
            if let currentUserId = socialManager.currentUserProfile?.id {
                userIds.append(currentUserId)
            }
            stats = await StatsService.shared.fetchStatsForUsers(userIds)
        } else {
            // Global - fetch all users
            stats = await fetchGlobalLeaderboard()
        }
        
        // Sort based on metric
        let sortedStats: [UserStats]
        switch selectedMetric {
        case .level:
            sortedStats = stats.sorted { $0.level > $1.level || ($0.level == $1.level && $0.totalXP > $1.totalXP) }
        case .weeklyVolume:
            sortedStats = stats.sorted { $0.weeklyVolume > $1.weeklyVolume }
        case .weeklyWorkouts:
            sortedStats = stats.sorted { $0.weeklyWorkouts > $1.weeklyWorkouts }
        case .streak:
            sortedStats = stats.sorted { $0.currentStreak > $1.currentStreak }
        }
        
        // Convert to LeaderboardStats
        let currentUserId = socialManager.currentUserProfile?.id
        let entries = sortedStats.enumerated().map { index, stat in
            LeaderboardStats(
                stats: stat,
                rank: index + 1,
                isCurrentUser: stat.userId == currentUserId
            )
        }
        
        await MainActor.run {
            leaderboardEntries = entries
            isLoading = false
        }
    }
    
    private func fetchGlobalLeaderboard() async -> [UserStats] {
        let db = Firestore.firestore()
        
        do {
            // Fetch all public profiles
            let snapshot = try await db.collectionGroup("profile")
                .whereField("isPublic", isEqualTo: true)
                .limit(to: 100)
                .getDocuments()
            
            var stats: [UserStats] = []
            
            for doc in snapshot.documents {
                let data = doc.data()
                
                // Get userId from the parent path
                let pathComponents = doc.reference.path.split(separator: "/")
                guard pathComponents.count >= 2,
                      let userIdIndex = pathComponents.firstIndex(of: "users"),
                      userIdIndex + 1 < pathComponents.count else {
                    continue
                }
                let userId = String(pathComponents[userIdIndex + 1])
                
                let stat = UserStats(
                    userId: userId,
                    username: data["username"] as? String ?? "",
                    displayName: data["displayName"] as? String ?? "Unknown",
                    level: data["level"] as? Int ?? 1,
                    totalXP: data["totalXP"] as? Int ?? 0,
                    totalWorkouts: data["totalWorkouts"] as? Int ?? 0,
                    currentStreak: data["currentStreak"] as? Int ?? 0,
                    longestStreak: data["longestStreak"] as? Int ?? 0,
                    totalVolume: 0,
                    weeklyWorkouts: 0,
                    weeklyVolume: 0,
                    isPublic: true
                )
                stats.append(stat)
            }
            
            return stats
        } catch {
            print("❌ [LEADERBOARD] Error fetching global leaderboard: \(error)")
            return []
        }
    }
}

// MARK: - Leaderboard Stats Entry

struct LeaderboardStats: Identifiable {
    let id = UUID()
    let stats: UserStats
    let rank: Int
    let isCurrentUser: Bool
}

// MARK: - Leaderboard Metric Chip

struct LeaderboardMetricChip: View {
    let metric: LeaderboardMetric
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: metric.iconName)
                    .font(.caption)
                
                Text(metric.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.utOrange : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Podium View

struct LeaderboardPodiumView: View {
    let entries: [LeaderboardStats]
    let metric: LeaderboardMetric
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // 2nd Place
            if entries.count > 1 {
                PodiumItemView(entry: entries[1], rank: 2, height: 80, metric: metric)
            }
            
            // 1st Place
            if entries.count > 0 {
                PodiumItemView(entry: entries[0], rank: 1, height: 100, metric: metric)
            }
            
            // 3rd Place
            if entries.count > 2 {
                PodiumItemView(entry: entries[2], rank: 3, height: 60, metric: metric)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Podium Item

struct PodiumItemView: View {
    let entry: LeaderboardStats
    let rank: Int
    let height: CGFloat
    let metric: LeaderboardMetric
    
    private var medalColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(.systemGray3)
        case 3: return .orange
        default: return .clear
        }
    }
    
    private var metricValue: String {
        switch metric {
        case .weeklyVolume:
            return "\(Int(entry.stats.weeklyVolume)) kg"
        case .weeklyWorkouts:
            return "\(entry.stats.weeklyWorkouts)"
        case .streak:
            return "\(entry.stats.currentStreak)"
        case .level:
            return "Lv. \(entry.stats.level)"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Avatar with Medal
            ZStack(alignment: .bottom) {
                NavigationLink(destination: UserProfileView(userId: entry.stats.userId)) {
                    Circle()
                        .fill(
                            entry.isCurrentUser ?
                            LinearGradient(colors: [.utOrange, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: rank == 1 ? 70 : 60, height: rank == 1 ? 70 : 60)
                        .overlay(
                            Text(String(entry.stats.displayName.prefix(1)).uppercased())
                                .font(rank == 1 ? .title2 : .title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .shadow(color: entry.isCurrentUser ? Color.utOrange.opacity(0.3) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                
                // Medal
                Image(systemName: "medal.fill")
                    .font(.title3)
                    .foregroundColor(medalColor)
                    .offset(y: 10)
            }
            
            // Name
            Text(entry.isCurrentUser ? "You" : entry.stats.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            // Value
            Text(metricValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.utOrange)
            
            // Podium
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.utOrange.opacity(0.8), Color.utOrange.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
                .overlay(
                    Text("\(rank)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRowView: View {
    let entry: LeaderboardStats
    let rank: Int
    let metric: LeaderboardMetric
    
    private var metricValue: String {
        switch metric {
        case .weeklyVolume:
            return "\(Int(entry.stats.weeklyVolume)) kg"
        case .weeklyWorkouts:
            return "\(entry.stats.weeklyWorkouts) workouts"
        case .streak:
            return "\(entry.stats.currentStreak) days"
        case .level:
            return "Level \(entry.stats.level)"
        }
    }
    
    var body: some View {
        NavigationLink(destination: UserProfileView(userId: entry.stats.userId)) {
            HStack(spacing: 12) {
                // Rank
                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .frame(width: 30)
                
                // Avatar
                Circle()
                    .fill(
                        entry.isCurrentUser ?
                        LinearGradient(colors: [.utOrange, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(entry.stats.displayName.prefix(1)).uppercased())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                // Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.isCurrentUser ? "You" : entry.stats.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("@\(entry.stats.username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Value
                Text(metricValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.utOrange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(entry.isCurrentUser ? Color.utOrange.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(entry.isCurrentUser ? Color.utOrange.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
