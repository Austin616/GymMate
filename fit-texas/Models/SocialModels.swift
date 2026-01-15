//
//  SocialModels.swift
//  fit-texas
//
//  Created by GymMate
//

import Foundation

// MARK: - User Profile (extended user data)

struct UserProfile: Codable, Identifiable {
    let id: String  // Firebase UID
    var username: String
    var displayName: String
    var bio: String
    var profileImageURL: String?
    var totalXP: Int
    var level: Int
    var currentStreak: Int
    var longestStreak: Int
    var totalWorkouts: Int
    var followersCount: Int
    var followingCount: Int
    var postsCount: Int
    var isCurrentlyWorkingOut: Bool
    var currentWorkoutStartTime: Date?
    var joinedDate: Date
    var isPublic: Bool  // Whether profile/workouts are visible to others
    var fcmToken: String?  // For push notifications
    
    enum CodingKeys: String, CodingKey {
        case id, username, displayName, bio, profileImageURL
        case totalXP, level, currentStreak, longestStreak, totalWorkouts
        case followersCount, followingCount, postsCount
        case isCurrentlyWorkingOut, currentWorkoutStartTime
        case joinedDate, isPublic, fcmToken
    }
    
    init(
        id: String,
        username: String,
        displayName: String,
        bio: String = "",
        profileImageURL: String? = nil,
        totalXP: Int = 0,
        level: Int = 1,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalWorkouts: Int = 0,
        followersCount: Int = 0,
        followingCount: Int = 0,
        postsCount: Int = 0,
        isCurrentlyWorkingOut: Bool = false,
        currentWorkoutStartTime: Date? = nil,
        joinedDate: Date = Date(),
        isPublic: Bool = true,
        fcmToken: String? = nil
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.totalXP = totalXP
        self.level = level
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalWorkouts = totalWorkouts
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.postsCount = postsCount
        self.isCurrentlyWorkingOut = isCurrentlyWorkingOut
        self.currentWorkoutStartTime = currentWorkoutStartTime
        self.joinedDate = joinedDate
        self.isPublic = isPublic
        self.fcmToken = fcmToken
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        displayName = try container.decode(String.self, forKey: .displayName)
        bio = try container.decodeIfPresent(String.self, forKey: .bio) ?? ""
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        totalXP = try container.decodeIfPresent(Int.self, forKey: .totalXP) ?? 0
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        totalWorkouts = try container.decodeIfPresent(Int.self, forKey: .totalWorkouts) ?? 0
        followersCount = try container.decodeIfPresent(Int.self, forKey: .followersCount) ?? 0
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount) ?? 0
        postsCount = try container.decodeIfPresent(Int.self, forKey: .postsCount) ?? 0
        isCurrentlyWorkingOut = try container.decodeIfPresent(Bool.self, forKey: .isCurrentlyWorkingOut) ?? false
        currentWorkoutStartTime = try container.decodeIfPresent(Date.self, forKey: .currentWorkoutStartTime)
        joinedDate = try container.decodeIfPresent(Date.self, forKey: .joinedDate) ?? Date()
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? true
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
    }
}

// MARK: - Follow Relationship

struct Follow: Codable, Identifiable {
    var id: String { "\(followerId)_\(followingId)" }
    let followerId: String  // User who is following
    let followingId: String // User being followed
    let createdAt: Date
    
    init(followerId: String, followingId: String, createdAt: Date = Date()) {
        self.followerId = followerId
        self.followingId = followingId
        self.createdAt = createdAt
    }
}

// MARK: - Friendship

struct Friendship: Codable, Identifiable {
    let id: String
    let userId: String
    let friendId: String
    let status: FriendshipStatus
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        friendId: String,
        status: FriendshipStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.friendId = friendId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
    case blocked
}

// MARK: - Social Feed Post (shared workout)

struct FeedPost: Codable, Identifiable {
    let id: String
    let userId: String
    let userDisplayName: String
    let userProfileImageURL: String?
    let workoutId: String
    let workoutName: String
    let workoutDate: Date
    let exerciseCount: Int
    let totalSets: Int
    let totalVolume: Double
    let duration: TimeInterval?
    let caption: String?
    let createdAt: Date
    var likesCount: Int
    var commentsCount: Int
    var isLikedByCurrentUser: Bool
    
    // Exercise summaries for display
    let exerciseSummaries: [ExerciseSummary]?
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        userDisplayName: String,
        userProfileImageURL: String? = nil,
        workoutId: String,
        workoutName: String,
        workoutDate: Date,
        exerciseCount: Int,
        totalSets: Int,
        totalVolume: Double,
        duration: TimeInterval? = nil,
        caption: String? = nil,
        createdAt: Date = Date(),
        likesCount: Int = 0,
        commentsCount: Int = 0,
        isLikedByCurrentUser: Bool = false,
        exerciseSummaries: [ExerciseSummary]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.userProfileImageURL = userProfileImageURL
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.workoutDate = workoutDate
        self.exerciseCount = exerciseCount
        self.totalSets = totalSets
        self.totalVolume = totalVolume
        self.duration = duration
        self.caption = caption
        self.createdAt = createdAt
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.isLikedByCurrentUser = isLikedByCurrentUser
        self.exerciseSummaries = exerciseSummaries
    }
}

// Helper struct for exercise summary in feed
struct ExerciseSummary: Codable {
    let name: String
    let setCount: Int
    let bestSet: String?  // e.g., "100kg x 8"
    
    init(name: String, setCount: Int, bestSet: String? = nil) {
        self.name = name
        self.setCount = setCount
        self.bestSet = bestSet
    }
}

// MARK: - Like on a post

struct PostLike: Codable, Identifiable {
    var id: String { "\(postId)_\(userId)" }
    let postId: String
    let userId: String
    let createdAt: Date
    
    init(postId: String, userId: String, createdAt: Date = Date()) {
        self.postId = postId
        self.userId = userId
        self.createdAt = createdAt
    }
}

// MARK: - Comment on a post

struct PostComment: Codable, Identifiable {
    let id: String
    let postId: String
    let userId: String
    let userDisplayName: String
    let userProfileImageURL: String?
    let text: String
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        postId: String,
        userId: String,
        userDisplayName: String,
        userProfileImageURL: String? = nil,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.userProfileImageURL = userProfileImageURL
        self.text = text
        self.createdAt = createdAt
    }
}

// MARK: - Friend Request Display Model

struct FriendRequest: Identifiable {
    let id: String
    let friendship: Friendship
    let fromUser: UserProfile
    
    init(friendship: Friendship, fromUser: UserProfile) {
        self.id = friendship.id
        self.friendship = friendship
        self.fromUser = fromUser
    }
}
