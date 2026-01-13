//
//  LeaderboardView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var socialManager = SocialManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedMetric: LeaderboardMetric = .level
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            CustomTabHeader(
                title: "Leaderboard",
                leadingButton: AnyView(
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
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
            
            // Metric Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LeaderboardMetric.allCases, id: \.self) { metric in
                        LeaderboardMetricChip(
                            metric: metric,
                            isSelected: selectedMetric == metric,
                            action: {
                                selectedMetric = metric
                                loadLeaderboard()
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            
            if socialManager.friends.isEmpty && socialManager.currentUserProfile == nil {
                // Empty State
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No Friends Yet")
                        .font(.headline)
                    
                    Text("Add friends to compete on the leaderboard!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding()
            } else if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Top 3 Podium
                        if leaderboardEntries.count >= 3 {
                            PodiumView(entries: Array(leaderboardEntries.prefix(3)), metric: selectedMetric)
                                .padding(.vertical, 20)
                        }
                        
                        // Rest of Leaderboard
                        VStack(spacing: 8) {
                            ForEach(Array(leaderboardEntries.enumerated()), id: \.element.id) { index, entry in
                                if index >= 3 {
                                    LeaderboardRow(entry: entry, rank: index + 1, metric: selectedMetric)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
                .refreshable {
                    loadLeaderboard()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadLeaderboard()
        }
    }
    
    private func loadLeaderboard() {
        isLoading = true
        
        Task {
            let entries = await socialManager.getFriendsLeaderboard(sortedBy: selectedMetric)
            
            await MainActor.run {
                leaderboardEntries = entries
                isLoading = false
            }
        }
    }
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

struct PodiumView: View {
    let entries: [LeaderboardEntry]
    let metric: LeaderboardMetric
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // 2nd Place
            if entries.count > 1 {
                PodiumItem(entry: entries[1], rank: 2, height: 80, metric: metric)
            }
            
            // 1st Place
            if entries.count > 0 {
                PodiumItem(entry: entries[0], rank: 1, height: 100, metric: metric)
            }
            
            // 3rd Place
            if entries.count > 2 {
                PodiumItem(entry: entries[2], rank: 3, height: 60, metric: metric)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Podium Item

struct PodiumItem: View {
    let entry: LeaderboardEntry
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
            return "\(entry.profile.totalXP)" // Placeholder
        case .weeklyWorkouts:
            return "\(entry.profile.totalWorkouts)"
        case .streak:
            return "\(entry.profile.currentStreak)"
        case .level:
            return "Lv. \(entry.profile.level)"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Avatar with Medal
            ZStack(alignment: .bottom) {
                Circle()
                    .fill(
                        entry.isCurrentUser ?
                        LinearGradient(colors: [.utOrange, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: rank == 1 ? 70 : 60, height: rank == 1 ? 70 : 60)
                    .overlay(
                        Text(String(entry.profile.displayName.prefix(1)).uppercased())
                            .font(rank == 1 ? .title2 : .title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .shadow(color: entry.isCurrentUser ? Color.utOrange.opacity(0.3) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Medal
                Image(systemName: "medal.fill")
                    .font(.title3)
                    .foregroundColor(medalColor)
                    .offset(y: 10)
            }
            
            // Name
            Text(entry.isCurrentUser ? "You" : entry.profile.displayName)
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

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let metric: LeaderboardMetric
    
    private var metricValue: String {
        switch metric {
        case .weeklyVolume:
            return "\(entry.profile.totalXP) XP"
        case .weeklyWorkouts:
            return "\(entry.profile.totalWorkouts) workouts"
        case .streak:
            return "\(entry.profile.currentStreak) days"
        case .level:
            return "Level \(entry.profile.level)"
        }
    }
    
    var body: some View {
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
                    Text(String(entry.profile.displayName.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.isCurrentUser ? "You" : entry.profile.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("@\(entry.profile.username)")
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
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
