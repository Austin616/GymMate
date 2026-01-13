//
//  GamificationModels.swift
//  fit-texas
//
//  Created by GymMate
//

import Foundation

// MARK: - Achievement Definition

struct Achievement: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let requirement: Int  // e.g., 7 for "7-day streak"
    let xpReward: Int
    
    init(
        id: String,
        name: String,
        description: String,
        iconName: String,
        category: AchievementCategory,
        requirement: Int,
        xpReward: Int
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.xpReward = xpReward
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "Streak"
    case workouts = "Workouts"
    case volume = "Volume"
    case social = "Social"
    case milestone = "Milestone"
    
    var iconName: String {
        switch self {
        case .streak: return "flame.fill"
        case .workouts: return "figure.strengthtraining.traditional"
        case .volume: return "scalemass.fill"
        case .social: return "person.2.fill"
        case .milestone: return "star.fill"
        }
    }
}

// MARK: - User's Unlocked Achievement

struct UserAchievement: Codable, Identifiable {
    let id: String
    let achievementId: String
    let unlockedAt: Date
    
    init(id: String = UUID().uuidString, achievementId: String, unlockedAt: Date = Date()) {
        self.id = id
        self.achievementId = achievementId
        self.unlockedAt = unlockedAt
    }
}

// MARK: - Challenge (weekly/monthly)

struct Challenge: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let type: ChallengeType
    let target: Int  // e.g., 5 workouts
    let xpReward: Int
    let startDate: Date
    let endDate: Date
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        type: ChallengeType,
        target: Int,
        xpReward: Int,
        startDate: Date,
        endDate: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.target = target
        self.xpReward = xpReward
        self.startDate = startDate
        self.endDate = endDate
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    var timeRemaining: TimeInterval {
        return endDate.timeIntervalSince(Date())
    }
    
    var formattedTimeRemaining: String {
        let remaining = timeRemaining
        if remaining <= 0 {
            return "Ended"
        }
        
        let days = Int(remaining / 86400)
        let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)
        
        if days > 0 {
            return "\(days)d \(hours)h left"
        } else if hours > 0 {
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m left"
        } else {
            let minutes = Int(remaining / 60)
            return "\(minutes)m left"
        }
    }
}

enum ChallengeType: String, Codable {
    case workoutCount = "Workout Count"
    case volumeTotal = "Total Volume"
    case streakDays = "Streak Days"
    case exerciseVariety = "Exercise Variety"
    
    var iconName: String {
        switch self {
        case .workoutCount: return "figure.strengthtraining.traditional"
        case .volumeTotal: return "scalemass.fill"
        case .streakDays: return "flame.fill"
        case .exerciseVariety: return "list.bullet"
        }
    }
}

// MARK: - User's Challenge Progress

struct UserChallenge: Codable, Identifiable {
    let id: String
    let challengeId: String
    var progress: Int
    var isCompleted: Bool
    var completedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        challengeId: String,
        progress: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.challengeId = challengeId
        self.progress = progress
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

// MARK: - XP Level System

struct LevelSystem {
    // Level thresholds: Level 1 = 0, Level 2 = 400, Level 3 = 900, etc.
    // Formula: level² × 100
    
    static func xpForLevel(_ level: Int) -> Int {
        return level * level * 100
    }
    
    static func levelFromXP(_ xp: Int) -> Int {
        var level = 1
        while xpForLevel(level + 1) <= xp {
            level += 1
        }
        return level
    }
    
    static func xpProgressInLevel(_ xp: Int) -> (current: Int, required: Int, percentage: Double) {
        let currentLevel = levelFromXP(xp)
        let currentLevelXP = xpForLevel(currentLevel)
        let nextLevelXP = xpForLevel(currentLevel + 1)
        
        let xpIntoLevel = xp - currentLevelXP
        let xpNeededForNext = nextLevelXP - currentLevelXP
        let percentage = Double(xpIntoLevel) / Double(xpNeededForNext)
        
        return (xpIntoLevel, xpNeededForNext, percentage)
    }
    
    static func levelTitle(for level: Int) -> String {
        switch level {
        case 1...5: return "Beginner"
        case 6...10: return "Intermediate"
        case 11...20: return "Advanced"
        case 21...35: return "Expert"
        case 36...50: return "Master"
        case 51...75: return "Elite"
        case 76...100: return "Legend"
        default: return "Mythic"
        }
    }
}

// MARK: - XP Rewards Configuration

struct XPRewards {
    // Base XP for completing a workout
    static let workoutCompletion = 100
    
    // Per-exercise bonus
    static let perExercise = 10
    
    // Per-set bonus
    static let perSet = 5
    
    // Volume bonus: XP per 100kg lifted
    static let volumeBonusPer100kg = 1
    
    // Streak bonus: XP per streak day (capped at 100)
    static let perStreakDay = 10
    static let maxStreakBonus = 100
    
    // First workout of the day bonus
    static let firstWorkoutOfDay = 50
    
    // Social XP
    static let receiveLike = 5
    static let receiveComment = 10
    static let addFriend = 25
    
    static func calculateWorkoutXP(
        exerciseCount: Int,
        setCount: Int,
        totalVolume: Double,
        streakDays: Int,
        isFirstWorkoutToday: Bool
    ) -> (total: Int, breakdown: XPBreakdown) {
        var total = workoutCompletion
        
        let exerciseXP = exerciseCount * perExercise
        total += exerciseXP
        
        let setXP = setCount * perSet
        total += setXP
        
        let volumeXP = Int(totalVolume / 100.0) * volumeBonusPer100kg
        total += volumeXP
        
        let streakXP = min(streakDays * perStreakDay, maxStreakBonus)
        total += streakXP
        
        var firstWorkoutXP = 0
        if isFirstWorkoutToday {
            firstWorkoutXP = firstWorkoutOfDay
            total += firstWorkoutXP
        }
        
        let breakdown = XPBreakdown(
            base: workoutCompletion,
            exercises: exerciseXP,
            sets: setXP,
            volume: volumeXP,
            streak: streakXP,
            firstWorkout: firstWorkoutXP
        )
        
        return (total, breakdown)
    }
}

struct XPBreakdown {
    let base: Int
    let exercises: Int
    let sets: Int
    let volume: Int
    let streak: Int
    let firstWorkout: Int
    
    var total: Int {
        base + exercises + sets + volume + streak + firstWorkout
    }
}

// MARK: - Predefined Achievements

struct PredefinedAchievements {
    static let all: [Achievement] = [
        // Streak Achievements
        Achievement(id: "streak_3", name: "Getting Started", description: "Achieve a 3-day workout streak", iconName: "flame", category: .streak, requirement: 3, xpReward: 50),
        Achievement(id: "streak_7", name: "Week Warrior", description: "Achieve a 7-day workout streak", iconName: "flame.fill", category: .streak, requirement: 7, xpReward: 150),
        Achievement(id: "streak_14", name: "Two Week Titan", description: "Achieve a 14-day workout streak", iconName: "flame.fill", category: .streak, requirement: 14, xpReward: 300),
        Achievement(id: "streak_30", name: "Monthly Master", description: "Achieve a 30-day workout streak", iconName: "flame.fill", category: .streak, requirement: 30, xpReward: 500),
        Achievement(id: "streak_100", name: "Unstoppable", description: "Achieve a 100-day workout streak", iconName: "flame.fill", category: .streak, requirement: 100, xpReward: 2000),
        
        // Workout Count Achievements
        Achievement(id: "workouts_1", name: "First Rep", description: "Complete your first workout", iconName: "figure.strengthtraining.traditional", category: .workouts, requirement: 1, xpReward: 50),
        Achievement(id: "workouts_10", name: "Dedicated", description: "Complete 10 workouts", iconName: "figure.strengthtraining.traditional", category: .workouts, requirement: 10, xpReward: 100),
        Achievement(id: "workouts_25", name: "Committed", description: "Complete 25 workouts", iconName: "figure.strengthtraining.traditional", category: .workouts, requirement: 25, xpReward: 250),
        Achievement(id: "workouts_50", name: "Half Century", description: "Complete 50 workouts", iconName: "figure.strengthtraining.traditional", category: .workouts, requirement: 50, xpReward: 500),
        Achievement(id: "workouts_100", name: "Century Club", description: "Complete 100 workouts", iconName: "figure.strengthtraining.traditional", category: .workouts, requirement: 100, xpReward: 1000),
        Achievement(id: "workouts_500", name: "Iron Veteran", description: "Complete 500 workouts", iconName: "figure.strengthtraining.traditional", category: .workouts, requirement: 500, xpReward: 5000),
        
        // Volume Achievements (in kg)
        Achievement(id: "volume_1k", name: "Ton Lifter", description: "Lift a total of 1,000 kg", iconName: "scalemass", category: .volume, requirement: 1000, xpReward: 50),
        Achievement(id: "volume_10k", name: "Heavy Hauler", description: "Lift a total of 10,000 kg", iconName: "scalemass.fill", category: .volume, requirement: 10000, xpReward: 150),
        Achievement(id: "volume_100k", name: "Mountain Mover", description: "Lift a total of 100,000 kg", iconName: "scalemass.fill", category: .volume, requirement: 100000, xpReward: 500),
        Achievement(id: "volume_1m", name: "Hercules", description: "Lift a total of 1,000,000 kg", iconName: "scalemass.fill", category: .volume, requirement: 1000000, xpReward: 2000),
        
        // Social Achievements
        Achievement(id: "social_friend_1", name: "Gym Buddy", description: "Add your first friend", iconName: "person.badge.plus", category: .social, requirement: 1, xpReward: 25),
        Achievement(id: "social_likes_10", name: "Popular", description: "Receive 10 likes on your posts", iconName: "heart.fill", category: .social, requirement: 10, xpReward: 100),
        Achievement(id: "social_comments_10", name: "Conversation Starter", description: "Make 10 comments on posts", iconName: "bubble.left.fill", category: .social, requirement: 10, xpReward: 100),
        Achievement(id: "social_share_1", name: "Sharer", description: "Share your first workout", iconName: "square.and.arrow.up", category: .social, requirement: 1, xpReward: 25),
        
        // Milestone Achievements
        Achievement(id: "milestone_profile", name: "Identity", description: "Complete your profile setup", iconName: "person.crop.circle.fill", category: .milestone, requirement: 1, xpReward: 50),
        Achievement(id: "milestone_level_5", name: "Rising Star", description: "Reach Level 5", iconName: "star", category: .milestone, requirement: 5, xpReward: 100),
        Achievement(id: "milestone_level_10", name: "Gym Regular", description: "Reach Level 10", iconName: "star.fill", category: .milestone, requirement: 10, xpReward: 250),
        Achievement(id: "milestone_level_25", name: "Fitness Enthusiast", description: "Reach Level 25", iconName: "star.circle.fill", category: .milestone, requirement: 25, xpReward: 500),
    ]
    
    static func achievement(byId id: String) -> Achievement? {
        return all.first { $0.id == id }
    }
    
    static func achievements(for category: AchievementCategory) -> [Achievement] {
        return all.filter { $0.category == category }
    }
}
