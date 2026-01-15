//
//  AchievementsView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI

struct AchievementsView: View {
    @StateObject private var gamificationManager = GamificationManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedCategory: AchievementCategory?
    
    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return PredefinedAchievements.achievements(for: category)
        }
        return PredefinedAchievements.all
    }
    
    private var unlockedCount: Int {
        gamificationManager.unlockedAchievements.count
    }
    
    private var totalCount: Int {
        PredefinedAchievements.all.count
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // Progress Summary
                    VStack(spacing: 12) {
                        HStack {
                            Text("\(unlockedCount)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.utOrange)
                            
                            Text("/ \(totalCount)")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Achievements Unlocked")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: Double(unlockedCount), total: Double(totalCount))
                            .tint(.utOrange)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.utOrange.opacity(0.1), Color.utOrange.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryFilterChip(
                                title: "All",
                                icon: "trophy.fill",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(AchievementCategory.allCases, id: \.self) { category in
                                CategoryFilterChip(
                                    title: category.rawValue,
                                    icon: category.iconName,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Achievements Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                isUnlocked: gamificationManager.isAchievementUnlocked(achievement.id)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .padding(.top)
            }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
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

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    @StateObject private var gamificationManager = GamificationManager.shared
    
    @State private var showDetail = false
    
    var body: some View {
        Button(action: { showDetail = true }) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color.utOrange : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: achievement.iconName)
                        .font(.title2)
                        .foregroundColor(isUnlocked ? .white : .secondary)
                }
                
                // Name
                Text(achievement.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                // XP Reward
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("+\(achievement.xpReward) XP")
                        .font(.caption)
                }
                .foregroundColor(isUnlocked ? .utOrange : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isUnlocked ? Color.utOrange.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isUnlocked ? Color.utOrange.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
            .opacity(isUnlocked ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            AchievementDetailSheet(achievement: achievement, isUnlocked: isUnlocked)
        }
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    let isUnlocked: Bool
    @StateObject private var gamificationManager = GamificationManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        isUnlocked ?
                        LinearGradient(colors: [.utOrange, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: isUnlocked ? Color.utOrange.opacity(0.4) : Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            // Info
            VStack(spacing: 8) {
                Text(achievement.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(achievement.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.utOrange)
                    Text("+\(achievement.xpReward) XP")
                        .fontWeight(.semibold)
                }
                .font(.title3)
                .padding(.top, 8)
            }
            
            // Progress (if not unlocked)
            if !isUnlocked {
                let progress = gamificationManager.getAchievementProgress(for: achievement)
                
                VStack(spacing: 8) {
                    ProgressView(value: Double(progress.current), total: Double(progress.target))
                        .tint(.utOrange)
                    
                    Text("\(progress.current) / \(progress.target)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
                .padding(.top, 16)
            }
            
            // Status
            HStack(spacing: 8) {
                Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundColor(isUnlocked ? .green : .secondary)
                
                Text(isUnlocked ? "Unlocked" : "Locked")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isUnlocked ? .green : .secondary)
            }
            .padding(.top, 8)
            
            Spacer()
            Spacer()
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
}
