//
//  AuthManager.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI
import FirebaseAuth
internal import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    private var listenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        self.currentUser = Auth.auth().currentUser
        self.isAuthenticated = currentUser != nil

        // Save the handle so you can remove the listener later
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }

    deinit {
        // Clean up the listener when manager is destroyed
        if let listenerHandle = listenerHandle {
            Auth.auth().removeStateDidChangeListener(listenerHandle)
        }
    }

    func signOut() {
        do {
            // Clear all local caches before signing out
            clearAllLocalData()
            
            // Reset all singleton managers
            resetAllManagers()
            
            try Auth.auth().signOut()
            print("✅ [AUTH] Signed out successfully")
        } catch {
            print("❌ [AUTH] Error signing out: \(error.localizedDescription)")
        }
    }
    
    private func clearAllLocalData() {
        // Clear UserDefaults for app-specific keys
        let keysToRemove = [
            "stepDailyGoal",
            "cachedWorkouts",
            "lastSyncDate"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Clear any cached data in app's document directory if needed
        print("🧹 [AUTH] Cleared local data caches")
    }
    
    private func resetAllManagers() {
        // Force reset published properties on all managers
        // The auth listeners in each manager will handle the full reset,
        // but we trigger an immediate UI update here
        
        DispatchQueue.main.async {
            // SocialManager will be reset by its auth listener
            SocialManager.shared.currentUserProfile = nil
            SocialManager.shared.friends = []
            SocialManager.shared.pendingRequests = []
            SocialManager.shared.hasCompletedProfileSetup = false
            
            // FeedManager will be reset by its auth listener
            FeedManager.shared.feedPosts = []
            FeedManager.shared.suggestedUsers = []
            
            // GamificationManager will be reset by its auth listener
            GamificationManager.shared.totalXP = 0
            GamificationManager.shared.currentLevel = 1
            GamificationManager.shared.unlockedAchievements = []
            GamificationManager.shared.activeChallenges = []
            GamificationManager.shared.userChallenges = []
        }
        
        print("🔄 [AUTH] Reset all managers")
    }
}
