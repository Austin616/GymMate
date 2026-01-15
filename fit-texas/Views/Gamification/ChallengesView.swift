//
//  ChallengesView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI

struct ChallengesView: View {
    @StateObject private var gamificationManager = GamificationManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Group {
            if gamificationManager.activeChallenges.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No Active Challenges")
                        .font(.headline)
                    
                    Text("Check back soon for new challenges!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(gamificationManager.activeChallenges) { challenge in
                            ChallengeCard(challenge: challenge)
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Challenge Card

struct ChallengeCard: View {
    let challenge: Challenge
    @StateObject private var gamificationManager = GamificationManager.shared
    
    private var userChallenge: UserChallenge? {
        gamificationManager.getChallengeProgress(for: challenge.id)
    }
    
    private var progress: Int {
        userChallenge?.progress ?? 0
    }
    
    private var isCompleted: Bool {
        userChallenge?.isCompleted ?? false
    }
    
    private var progressPercentage: Double {
        min(Double(progress) / Double(challenge.target), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green.opacity(0.2) : Color.utOrange.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isCompleted ? "checkmark" : challenge.type.iconName)
                        .font(.title3)
                        .foregroundColor(isCompleted ? .green : .utOrange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                    
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time Remaining / Status
                if isCompleted {
                    Text("Complete!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(challenge.formattedTimeRemaining)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Progress Bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                isCompleted ?
                                LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.utOrange, .orange], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geometry.size.width * progressPercentage, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(progress) / \(challenge.target)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.utOrange)
                        Text("+\(challenge.xpReward) XP")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.utOrange)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Challenge Preview Card (for HomeView)

struct ChallengePreviewCard: View {
    let challenge: Challenge
    @StateObject private var gamificationManager = GamificationManager.shared
    
    private var userChallenge: UserChallenge? {
        gamificationManager.getChallengeProgress(for: challenge.id)
    }
    
    private var progress: Int {
        userChallenge?.progress ?? 0
    }
    
    private var isCompleted: Bool {
        userChallenge?.isCompleted ?? false
    }
    
    private var progressPercentage: Double {
        min(Double(progress) / Double(challenge.target), 1.0)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green.opacity(0.2) : Color.utOrange.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isCompleted ? "checkmark" : challenge.type.iconName)
                    .font(.subheadline)
                    .foregroundColor(isCompleted ? .green : .utOrange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isCompleted ? Color.green : Color.utOrange)
                            .frame(width: geometry.size.width * progressPercentage, height: 4)
                    }
                }
                .frame(height: 4)
                
                Text("\(progress)/\(challenge.target) • \(challenge.formattedTimeRemaining)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // XP Reward
            VStack(alignment: .trailing) {
                Text("+\(challenge.xpReward)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.utOrange)
                Text("XP")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ChallengesView()
    }
}
