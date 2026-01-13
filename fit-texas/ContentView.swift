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
    @State private var showProfileSetup = false

    var body: some View {
        ZStack {
            if authManager.isAuthenticated {
                if socialManager.hasCompletedProfileSetup {
                    // Show main app with custom tab bar
                    CustomTabBarView(selectedTab: $selectedTab)
                        .environmentObject(authManager)
                        .achievementToast()
                        .levelUpOverlay(
                            isPresented: $gamificationManager.showLevelUpCelebration,
                            level: gamificationManager.newLevel
                        )
                } else {
                    // Show profile setup for new users
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

#Preview {
    ContentView()
        .environmentObject(WorkoutTimerManager.shared)
}
