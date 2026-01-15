//
//  ContentView.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    @StateObject private var socialManager = SocialManager.shared
    @StateObject private var gamificationManager = GamificationManager.shared
    @State private var selectedTab: TabItem = .home

    var body: some View {
        ZStack {
            if authManager.isAuthenticated {
                if socialManager.isCheckingProfile {
                    // Show loading while checking if profile exists
                    LoadingView()
                } else if socialManager.hasCompletedProfileSetup {
                    // Show main app with custom tab bar
                    CustomTabBarView(selectedTab: $selectedTab)
                        .environmentObject(authManager)
                        .achievementToast()
                        .levelUpOverlay(
                            isPresented: $gamificationManager.showLevelUpCelebration,
                            level: gamificationManager.newLevel
                        )
                } else {
                    // Show profile setup for new users only
                    ProfileSetupView(onComplete: {
                        // Profile setup completed
                    })
                    .environmentObject(authManager)
                }
            } else {
                // Show login view
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // Request notification permissions
            Task {
                _ = await NotificationManager.shared.requestAuthorization()
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutTimerManager.shared)
}
