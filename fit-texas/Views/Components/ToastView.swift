//
//  ToastView.swift
//  fit-texas
//
//  Created by Claude Code
//

import SwiftUI

struct ToastView: View {
    let message: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Achievement Unlock Toast

struct AchievementToastView: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            // Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.utOrange, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: achievement.iconName)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked!")
                    .font(.caption)
                    .foregroundColor(.utOrange)
                    .fontWeight(.semibold)
                
                Text(achievement.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("+\(achievement.xpReward) XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.utOrange.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.utOrange.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Achievement Toast Modifier

struct AchievementToastModifier: ViewModifier {
    @ObservedObject var gamificationManager = GamificationManager.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let achievement = gamificationManager.recentlyUnlockedAchievement {
                VStack {
                    AchievementToastView(achievement: achievement)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture {
                            gamificationManager.dismissAchievementToast()
                        }
                    
                    Spacer()
                }
                .padding(.top, 60)
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: gamificationManager.recentlyUnlockedAchievement != nil)
    }
}

extension View {
    func achievementToast() -> some View {
        modifier(AchievementToastModifier())
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let icon: String
    let color: Color
    let duration: TimeInterval

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if isPresented {
                VStack {
                    ToastView(message: message, icon: icon, color: color)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isPresented = false
                                }
                            }
                        }

                    Spacer()
                }
                .padding(.top, 60)
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill", color: Color = .green, duration: TimeInterval = 2.0) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, icon: icon, color: color, duration: duration))
    }
}

#Preview {
    VStack {
        Text("Content")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay(alignment: .top) {
        VStack {
            ToastView(message: "Exercise added to favorites", icon: "star.fill", color: .utOrange)
            Spacer()
        }
        .padding(.top, 60)
    }
}
