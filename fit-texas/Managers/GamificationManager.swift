//
//  GamificationManager.swift
//  fit-texas
//
//  Created by GymMate
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
internal import Combine

class GamificationManager: ObservableObject {
    static let shared = GamificationManager()
    
    @Published var totalXP: Int = 0
    @Published var currentLevel: Int = 1
    @Published var unlockedAchievements: [UserAchievement] = []
    @Published var activeChallenges: [Challenge] = []
    @Published var userChallenges: [UserChallenge] = []
    @Published var recentlyUnlockedAchievement: Achievement?
    @Published var showLevelUpCelebration: Bool = false
    @Published var newLevel: Int = 0
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var achievementsListener: ListenerRegistration?
    private var challengesListener: ListenerRegistration?
    
    private init() {
        print("🔵 [GAMIFICATION] Initializing GamificationManager...")
        setupAuthListener()
    }
    
    deinit {
        achievementsListener?.remove()
        challengesListener?.remove()
    }
    
    // MARK: - Auth Listener
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.loadUserGamificationData(userId: user.uid)
                self?.setupAchievementsListener(userId: user.uid)
                self?.loadActiveChallenges(userId: user.uid)
            } else {
                self?.resetState()
            }
        }
    }
    
    private func resetState() {
        print("🧹 [GAMIFICATION] Removing listeners and resetting state")
        achievementsListener?.remove()
        achievementsListener = nil
        challengesListener?.remove()
        challengesListener = nil
        
        DispatchQueue.main.async {
            self.totalXP = 0
            self.currentLevel = 1
            self.unlockedAchievements = []
            self.activeChallenges = []
            self.userChallenges = []
            self.recentlyUnlockedAchievement = nil
            self.showLevelUpCelebration = false
        }
        print("🧹 [GAMIFICATION] State reset")
    }
    
    // MARK: - Load Data
    
    private func loadUserGamificationData(userId: String) {
        print("🔵 [GAMIFICATION] Loading user data for: \(userId)")
        
        // Fetch directly from Firestore instead of relying on SocialManager
        db.collection("users").document(userId)
            .collection("profile").document("data")
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [GAMIFICATION] Error loading user data: \(error)")
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("ℹ️ [GAMIFICATION] No profile data found")
                    return
                }
                
                let loadedXP = data["totalXP"] as? Int ?? 0
                let loadedLevel = data["level"] as? Int ?? 1
                
                DispatchQueue.main.async {
                    self.totalXP = loadedXP
                    self.currentLevel = loadedLevel
                    print("✅ [GAMIFICATION] Loaded XP: \(self.totalXP), Level: \(self.currentLevel)")
                    
                    // If XP is 0 but we have achievements, recalculate
                    if loadedXP == 0 {
                        Task {
                            await self.syncXPFromAchievements(userId: userId)
                        }
                    }
                }
            }
    }
    
    // Recalculate XP from unlocked achievements (for users with missing XP data)
    private func syncXPFromAchievements(userId: String) async {
        print("🔵 [GAMIFICATION] Syncing XP from achievements...")
        
        do {
            // Fetch all user achievements
            let snapshot = try await db.collection("users").document(userId)
                .collection("achievements")
                .getDocuments()
            
            guard !snapshot.documents.isEmpty else {
                print("ℹ️ [GAMIFICATION] No achievements to sync")
                return
            }
            
            // Calculate total XP from achievements
            var calculatedXP = 0
            for doc in snapshot.documents {
                if let achievementId = doc.data()["achievementId"] as? String,
                   let achievement = PredefinedAchievements.achievement(byId: achievementId) {
                    calculatedXP += achievement.xpReward
                    print("   + \(achievement.xpReward) XP from \(achievement.name)")
                }
            }
            
            guard calculatedXP > 0 else {
                print("ℹ️ [GAMIFICATION] No XP to sync")
                return
            }
            
            let calculatedLevel = LevelSystem.levelFromXP(calculatedXP)
            
            // Save to Firestore
            try await db.collection("users").document(userId)
                .collection("profile").document("data")
                .setData([
                    "totalXP": calculatedXP,
                    "level": calculatedLevel
                ], merge: true)
            
            // Update local state
            DispatchQueue.main.async {
                self.totalXP = calculatedXP
                self.currentLevel = calculatedLevel
                print("✅ [GAMIFICATION] Synced XP: \(calculatedXP), Level: \(calculatedLevel)")
            }
        } catch {
            print("❌ [GAMIFICATION] Error syncing XP: \(error)")
        }
    }
    
    private func setupAchievementsListener(userId: String) {
        achievementsListener?.remove()
        
        achievementsListener = db.collection("users").document(userId)
            .collection("achievements")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let achievements = documents.compactMap { doc -> UserAchievement? in
                    try? doc.data(as: UserAchievement.self)
                }
                
                DispatchQueue.main.async {
                    self?.unlockedAchievements = achievements
                    print("🔄 [GAMIFICATION] Achievements updated: \(achievements.count)")
                }
            }
    }
    
    private func loadActiveChallenges(userId: String) {
        print("🔵 [GAMIFICATION] Loading active challenges...")
        
        let now = Date()
        
        db.collection("challenges")
            .whereField("endDate", isGreaterThan: now)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let challenges = documents.compactMap { doc -> Challenge? in
                    try? doc.data(as: Challenge.self)
                }
                
                DispatchQueue.main.async {
                    self?.activeChallenges = challenges
                    print("✅ [GAMIFICATION] Loaded \(challenges.count) active challenges")
                }
                
                // Load user's progress for these challenges
                self?.loadUserChallengeProgress(userId: userId, challengeIds: challenges.map { $0.id })
            }
    }
    
    private func loadUserChallengeProgress(userId: String, challengeIds: [String]) {
        guard !challengeIds.isEmpty else { return }
        
        db.collection("users").document(userId)
            .collection("challenges")
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let userChallenges = documents.compactMap { doc -> UserChallenge? in
                    try? doc.data(as: UserChallenge.self)
                }
                
                DispatchQueue.main.async {
                    self?.userChallenges = userChallenges
                }
            }
    }
    
    // MARK: - XP Management
    
    func awardXP(amount: Int, reason: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("🔵 [GAMIFICATION] Awarding \(amount) XP for: \(reason)")
        
        let previousLevel = currentLevel
        let newTotalXP = totalXP + amount
        let calculatedLevel = LevelSystem.levelFromXP(newTotalXP)
        
        // Update in Firestore (use setData with merge to handle new documents)
        try await db.collection("users").document(userId)
            .collection("profile").document("data")
            .setData([
                "totalXP": newTotalXP,
                "level": calculatedLevel
            ], merge: true)
        
        // Update local state
        DispatchQueue.main.async {
            self.totalXP = newTotalXP
            self.currentLevel = calculatedLevel
            
            // Check for level up
            if calculatedLevel > previousLevel {
                self.newLevel = calculatedLevel
                self.showLevelUpCelebration = true
                print("🎉 [GAMIFICATION] Level up! Now level \(calculatedLevel)")
            }
        }
        
        // Update social manager's profile
        if var profile = SocialManager.shared.currentUserProfile {
            profile.totalXP = newTotalXP
            profile.level = calculatedLevel
            SocialManager.shared.updateUserProfile(profile)
        }
        
        // Check for level-based achievements
        await checkLevelAchievements(level: calculatedLevel)
        
        print("✅ [GAMIFICATION] XP awarded. Total: \(newTotalXP), Level: \(calculatedLevel)")
    }
    
    // MARK: - Workout Completion
    
    func processWorkoutCompletion(
        exerciseCount: Int,
        setCount: Int,
        totalVolume: Double,
        workoutCount: Int,
        streakDays: Int
    ) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("🔵 [GAMIFICATION] Processing workout completion...")
        
        // Update profile stats (totalWorkouts, currentStreak, longestStreak)
        await updateProfileStats(userId: userId, workoutCount: workoutCount, streakDays: streakDays)
        
        // Check if this is the first workout today
        let isFirstWorkoutToday = await checkFirstWorkoutToday(userId: userId)
        
        // Calculate XP
        let (xpAmount, breakdown) = XPRewards.calculateWorkoutXP(
            exerciseCount: exerciseCount,
            setCount: setCount,
            totalVolume: totalVolume,
            streakDays: streakDays,
            isFirstWorkoutToday: isFirstWorkoutToday
        )
        
        print("📊 [GAMIFICATION] XP Breakdown:")
        print("   Base: \(breakdown.base)")
        print("   Exercises: \(breakdown.exercises)")
        print("   Sets: \(breakdown.sets)")
        print("   Volume: \(breakdown.volume)")
        print("   Streak: \(breakdown.streak)")
        print("   First Workout: \(breakdown.firstWorkout)")
        print("   Total: \(xpAmount)")
        
        // Award XP
        do {
            try await awardXP(amount: xpAmount, reason: "Workout completion")
        } catch {
            print("❌ [GAMIFICATION] Error awarding XP: \(error)")
        }
        
        // Check achievements
        await checkWorkoutAchievements(workoutCount: workoutCount)
        await checkStreakAchievements(streak: streakDays)
        await checkVolumeAchievements(userId: userId)
        
        // Update challenge progress
        await updateChallengeProgress(
            workoutCount: 1,
            volume: totalVolume,
            exerciseCount: exerciseCount
        )
    }
    
    private func updateProfileStats(userId: String, workoutCount: Int, streakDays: Int) async {
        print("🔵 [GAMIFICATION] Updating profile stats...")
        
        // Get current longest streak
        var longestStreak = streakDays
        if let currentProfile = SocialManager.shared.currentUserProfile {
            longestStreak = max(currentProfile.longestStreak, streakDays)
        }
        
        do {
            try await db.collection("users").document(userId)
                .collection("profile").document("data")
                .updateData([
                    "totalWorkouts": workoutCount,
                    "currentStreak": streakDays,
                    "longestStreak": longestStreak
                ])
            
            // Update local profile
            DispatchQueue.main.async {
                if var profile = SocialManager.shared.currentUserProfile {
                    profile.totalWorkouts = workoutCount
                    profile.currentStreak = streakDays
                    profile.longestStreak = longestStreak
                    SocialManager.shared.currentUserProfile = profile
                }
            }
            
            print("✅ [GAMIFICATION] Profile stats updated")
        } catch {
            print("❌ [GAMIFICATION] Error updating profile stats: \(error)")
        }
    }
    
    private func checkFirstWorkoutToday(userId: String) async -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("workouts")
                .whereField("date", isGreaterThanOrEqualTo: startOfDay)
                .limit(to: 2)
                .getDocuments()
            
            // If only 1 workout (the one being saved), it's the first
            return snapshot.documents.count <= 1
        } catch {
            return true
        }
    }
    
    // MARK: - Achievement Checking
    
    private func checkWorkoutAchievements(workoutCount: Int) async {
        let workoutAchievements = PredefinedAchievements.achievements(for: .workouts)
        
        for achievement in workoutAchievements {
            if workoutCount >= achievement.requirement {
                await unlockAchievementIfNeeded(achievement)
            }
        }
    }
    
    private func checkStreakAchievements(streak: Int) async {
        let streakAchievements = PredefinedAchievements.achievements(for: .streak)
        
        for achievement in streakAchievements {
            if streak >= achievement.requirement {
                await unlockAchievementIfNeeded(achievement)
            }
        }
    }
    
    private func checkVolumeAchievements(userId: String) async {
        // Calculate total volume from all workouts
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("workouts")
                .getDocuments()
            
            var totalVolume: Double = 0
            
            for doc in snapshot.documents {
                if let exercises = doc.data()["exercises"] as? [[String: Any]] {
                    for exercise in exercises {
                        if let sets = exercise["sets"] as? [[String: Any]] {
                            for set in sets {
                                let weight = Double(set["weight"] as? String ?? "0") ?? 0
                                let reps = Double(set["reps"] as? String ?? "0") ?? 0
                                totalVolume += weight * reps
                            }
                        }
                    }
                }
            }
            
            let volumeAchievements = PredefinedAchievements.achievements(for: .volume)
            
            for achievement in volumeAchievements {
                if Int(totalVolume) >= achievement.requirement {
                    await unlockAchievementIfNeeded(achievement)
                }
            }
        } catch {
            print("❌ [GAMIFICATION] Error checking volume achievements: \(error)")
        }
    }
    
    private func checkLevelAchievements(level: Int) async {
        let milestoneAchievements = PredefinedAchievements.achievements(for: .milestone)
            .filter { $0.id.starts(with: "milestone_level") }
        
        for achievement in milestoneAchievements {
            if level >= achievement.requirement {
                await unlockAchievementIfNeeded(achievement)
            }
        }
    }
    
    func checkSocialAchievements(friendCount: Int? = nil, likesReceived: Int? = nil, commentsMade: Int? = nil, postsShared: Int? = nil) async {
        let socialAchievements = PredefinedAchievements.achievements(for: .social)
        
        for achievement in socialAchievements {
            var shouldUnlock = false
            
            switch achievement.id {
            case "social_friend_1":
                if let count = friendCount, count >= achievement.requirement {
                    shouldUnlock = true
                }
            case "social_likes_10":
                if let count = likesReceived, count >= achievement.requirement {
                    shouldUnlock = true
                }
            case "social_comments_10":
                if let count = commentsMade, count >= achievement.requirement {
                    shouldUnlock = true
                }
            case "social_share_1":
                if let count = postsShared, count >= achievement.requirement {
                    shouldUnlock = true
                }
            default:
                break
            }
            
            if shouldUnlock {
                await unlockAchievementIfNeeded(achievement)
            }
        }
    }
    
    private func unlockAchievementIfNeeded(_ achievement: Achievement) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Check if already unlocked
        if unlockedAchievements.contains(where: { $0.achievementId == achievement.id }) {
            return
        }
        
        print("🏆 [GAMIFICATION] Unlocking achievement: \(achievement.name)")
        
        let userAchievement = UserAchievement(achievementId: achievement.id)
        
        do {
            try db.collection("users").document(userId)
                .collection("achievements").document(userAchievement.id)
                .setData(from: userAchievement)
            
            // Award XP for achievement
            try await awardXP(amount: achievement.xpReward, reason: "Achievement: \(achievement.name)")
            
            // Show achievement toast
            DispatchQueue.main.async {
                self.recentlyUnlockedAchievement = achievement
            }
            
            // Clear after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if self.recentlyUnlockedAchievement?.id == achievement.id {
                    self.recentlyUnlockedAchievement = nil
                }
            }
            
            print("✅ [GAMIFICATION] Achievement unlocked!")
        } catch {
            print("❌ [GAMIFICATION] Error unlocking achievement: \(error)")
        }
    }
    
    // MARK: - Challenge Management
    
    private func updateChallengeProgress(workoutCount: Int, volume: Double, exerciseCount: Int) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        for challenge in activeChallenges {
            guard challenge.isActive else { continue }
            
            var progressIncrement = 0
            
            switch challenge.type {
            case .workoutCount:
                progressIncrement = workoutCount
            case .volumeTotal:
                progressIncrement = Int(volume)
            case .exerciseVariety:
                progressIncrement = exerciseCount
            case .streakDays:
                // Streak is handled differently
                continue
            }
            
            if progressIncrement > 0 {
                await updateUserChallenge(challengeId: challenge.id, progressIncrement: progressIncrement, target: challenge.target, xpReward: challenge.xpReward, userId: userId)
            }
        }
    }
    
    private func updateUserChallenge(challengeId: String, progressIncrement: Int, target: Int, xpReward: Int, userId: String) async {
        let challengeRef = db.collection("users").document(userId)
            .collection("challenges").document(challengeId)
        
        do {
            let doc = try await challengeRef.getDocument()
            
            var userChallenge: UserChallenge
            
            if doc.exists, let existing = try? doc.data(as: UserChallenge.self) {
                // Already completed, skip
                if existing.isCompleted { return }
                
                userChallenge = existing
                userChallenge.progress += progressIncrement
            } else {
                userChallenge = UserChallenge(
                    id: challengeId,
                    challengeId: challengeId,
                    progress: progressIncrement
                )
            }
            
            // Check if completed
            if userChallenge.progress >= target && !userChallenge.isCompleted {
                userChallenge.isCompleted = true
                userChallenge.completedAt = Date()
                
                // Award XP for challenge completion
                try await awardXP(amount: xpReward, reason: "Challenge completed")
                
                print("🏆 [GAMIFICATION] Challenge completed!")
            }
            
            try challengeRef.setData(from: userChallenge)
            
            // Update local state
            DispatchQueue.main.async {
                if let index = self.userChallenges.firstIndex(where: { $0.challengeId == challengeId }) {
                    self.userChallenges[index] = userChallenge
                } else {
                    self.userChallenges.append(userChallenge)
                }
            }
        } catch {
            print("❌ [GAMIFICATION] Error updating challenge progress: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    func getAchievementProgress(for achievement: Achievement) -> (current: Int, target: Int) {
        let profile = SocialManager.shared.currentUserProfile
        
        switch achievement.category {
        case .workouts:
            let current = profile?.totalWorkouts ?? WorkoutHistoryManager.shared.savedWorkouts.count
            return (current, achievement.requirement)
        case .streak:
            let current = profile?.currentStreak ?? 0
            return (current, achievement.requirement)
        case .social:
            let current = profile?.followersCount ?? 0
            return (current, achievement.requirement)
        case .volume:
            // Calculate total volume from saved workouts
            let totalVolume = WorkoutHistoryManager.shared.savedWorkouts.reduce(0.0) { $0 + $1.totalVolume }
            return (Int(totalVolume), achievement.requirement)
        case .milestone:
            if achievement.id.contains("level") {
                return (currentLevel, achievement.requirement)
            }
            return (0, achievement.requirement)
        }
    }
    
    func isAchievementUnlocked(_ achievementId: String) -> Bool {
        return unlockedAchievements.contains { $0.achievementId == achievementId }
    }
    
    func getChallengeProgress(for challengeId: String) -> UserChallenge? {
        return userChallenges.first { $0.challengeId == challengeId }
    }
    
    func dismissLevelUp() {
        showLevelUpCelebration = false
    }
    
    func dismissAchievementToast() {
        recentlyUnlockedAchievement = nil
    }
}
