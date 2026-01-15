//
//  StatsService.swift
//  fit-texas
//
//  Simple modular API for fetching user stats
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - User Stats Model

struct UserStats: Codable {
    let userId: String
    let username: String
    let displayName: String
    let level: Int
    let totalXP: Int
    let totalWorkouts: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalVolume: Double
    let weeklyWorkouts: Int
    let weeklyVolume: Double
    let isPublic: Bool
    
    static let empty = UserStats(
        userId: "",
        username: "",
        displayName: "Unknown",
        level: 1,
        totalXP: 0,
        totalWorkouts: 0,
        currentStreak: 0,
        longestStreak: 0,
        totalVolume: 0,
        weeklyWorkouts: 0,
        weeklyVolume: 0,
        isPublic: true
    )
}

// MARK: - Stats Service

class StatsService {
    static let shared = StatsService()
    
    private let db = Firestore.firestore()
    private var statsCache: [String: (stats: UserStats, timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Public API
    
    /// Fetch stats for a specific user by ID
    func fetchStats(for userId: String, forceRefresh: Bool = false) async -> UserStats? {
        // Check cache first
        if !forceRefresh, let cached = statsCache[userId],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            return cached.stats
        }
        
        print("🔵 [STATS] Fetching stats for user: \(userId)")
        
        do {
            // Fetch profile
            let profileDoc = try await db.collection("users").document(userId)
                .collection("profile").document("data").getDocument()
            
            guard let profileData = profileDoc.data() else {
                print("❌ [STATS] No profile found for user: \(userId)")
                return nil
            }
            
            // Fetch workout stats
            let workoutStats = await fetchWorkoutStats(for: userId)
            
            let stats = UserStats(
                userId: userId,
                username: profileData["username"] as? String ?? "",
                displayName: profileData["displayName"] as? String ?? "Unknown",
                level: profileData["level"] as? Int ?? 1,
                totalXP: profileData["totalXP"] as? Int ?? 0,
                totalWorkouts: profileData["totalWorkouts"] as? Int ?? workoutStats.totalWorkouts,
                currentStreak: profileData["currentStreak"] as? Int ?? 0,
                longestStreak: profileData["longestStreak"] as? Int ?? 0,
                totalVolume: workoutStats.totalVolume,
                weeklyWorkouts: workoutStats.weeklyWorkouts,
                weeklyVolume: workoutStats.weeklyVolume,
                isPublic: profileData["isPublic"] as? Bool ?? true
            )
            
            // Cache the result
            statsCache[userId] = (stats, Date())
            
            print("✅ [STATS] Stats fetched for \(stats.displayName)")
            return stats
            
        } catch {
            print("❌ [STATS] Error fetching stats: \(error)")
            return nil
        }
    }
    
    /// Fetch stats for multiple users (for leaderboard)
    func fetchStatsForUsers(_ userIds: [String]) async -> [UserStats] {
        var results: [UserStats] = []
        
        await withTaskGroup(of: UserStats?.self) { group in
            for userId in userIds {
                group.addTask {
                    await self.fetchStats(for: userId)
                }
            }
            
            for await stats in group {
                if let stats = stats {
                    results.append(stats)
                }
            }
        }
        
        return results
    }
    
    /// Fetch stats for current user
    func fetchCurrentUserStats(forceRefresh: Bool = false) async -> UserStats? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        return await fetchStats(for: userId, forceRefresh: forceRefresh)
    }
    
    /// Clear cache (call on sign out)
    func clearCache() {
        statsCache.removeAll()
        print("🧹 [STATS] Cache cleared")
    }
    
    /// Clear cache for specific user
    func invalidateCache(for userId: String) {
        statsCache.removeValue(forKey: userId)
    }
    
    // MARK: - Private Helpers
    
    private func fetchWorkoutStats(for userId: String) async -> (totalWorkouts: Int, totalVolume: Double, weeklyWorkouts: Int, weeklyVolume: Double) {
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("workouts")
                .getDocuments()
            
            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            
            var totalWorkouts = 0
            var totalVolume: Double = 0
            var weeklyWorkouts = 0
            var weeklyVolume: Double = 0
            
            for doc in snapshot.documents {
                totalWorkouts += 1
                
                let data = doc.data()
                var workoutVolume: Double = 0
                
                if let exercises = data["exercises"] as? [[String: Any]] {
                    for exercise in exercises {
                        if let sets = exercise["sets"] as? [[String: Any]] {
                            for set in sets {
                                let weight = Double(set["weight"] as? String ?? "0") ?? 0
                                let reps = Double(set["reps"] as? String ?? "0") ?? 0
                                workoutVolume += weight * reps
                            }
                        }
                    }
                }
                
                totalVolume += workoutVolume
                
                // Check if this week
                if let timestamp = data["date"] as? Timestamp {
                    let workoutDate = timestamp.dateValue()
                    if workoutDate >= weekAgo {
                        weeklyWorkouts += 1
                        weeklyVolume += workoutVolume
                    }
                }
            }
            
            return (totalWorkouts, totalVolume, weeklyWorkouts, weeklyVolume)
            
        } catch {
            print("❌ [STATS] Error fetching workout stats: \(error)")
            return (0, 0, 0, 0)
        }
    }
}

// MARK: - Leaderboard Helpers

extension StatsService {
    
    enum LeaderboardSort {
        case level
        case xp
        case workouts
        case streak
        case weeklyVolume
    }
    
    func getLeaderboard(userIds: [String], sortBy: LeaderboardSort) async -> [UserStats] {
        let stats = await fetchStatsForUsers(userIds)
        
        switch sortBy {
        case .level:
            return stats.sorted { $0.level > $1.level }
        case .xp:
            return stats.sorted { $0.totalXP > $1.totalXP }
        case .workouts:
            return stats.sorted { $0.totalWorkouts > $1.totalWorkouts }
        case .streak:
            return stats.sorted { $0.currentStreak > $1.currentStreak }
        case .weeklyVolume:
            return stats.sorted { $0.weeklyVolume > $1.weeklyVolume }
        }
    }
}
