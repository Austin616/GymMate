//
//  SocialManager.swift
//  fit-texas
//
//  Created by GymMate
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
internal import Combine

class SocialManager: ObservableObject {
    static let shared = SocialManager()
    
    @Published var currentUserProfile: UserProfile?
    @Published var friends: [UserProfile] = []
    @Published var pendingRequests: [FriendRequest] = []
    @Published var isLoading: Bool = false
    @Published var hasCompletedProfileSetup: Bool = false
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var friendsListener: ListenerRegistration?
    private var requestsListener: ListenerRegistration?
    
    private init() {
        print("🔵 [SOCIAL] Initializing SocialManager...")
        setupAuthListener()
    }
    
    deinit {
        friendsListener?.remove()
        requestsListener?.remove()
    }
    
    // MARK: - Auth Listener
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchUserProfile(userId: user.uid)
                self?.setupFriendsListener(userId: user.uid)
                self?.setupRequestsListener(userId: user.uid)
            } else {
                self?.currentUserProfile = nil
                self?.friends = []
                self?.pendingRequests = []
                self?.hasCompletedProfileSetup = false
            }
        }
    }
    
    // MARK: - Profile Management
    
    func fetchUserProfile(userId: String) {
        print("🔵 [SOCIAL] Fetching profile for user: \(userId)")
        
        db.collection("users").document(userId).collection("profile").document("data")
            .getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("❌ [SOCIAL] Error fetching profile: \(error)")
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("ℹ️ [SOCIAL] No profile found for user")
                    self?.hasCompletedProfileSetup = false
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let profile = try JSONDecoder().decode(UserProfile.self, from: jsonData)
                    
                    DispatchQueue.main.async {
                        self?.currentUserProfile = profile
                        self?.hasCompletedProfileSetup = true
                        print("✅ [SOCIAL] Profile loaded: \(profile.username)")
                    }
                } catch {
                    print("❌ [SOCIAL] Error decoding profile: \(error)")
                    self?.hasCompletedProfileSetup = false
                }
            }
    }
    
    func createOrUpdateProfile(_ profile: UserProfile) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw SocialError.notAuthenticated
        }
        
        print("🔵 [SOCIAL] Saving profile for user: \(userId)")
        
        let data = try JSONEncoder().encode(profile)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        try await db.collection("users").document(userId).collection("profile").document("data")
            .setData(dict)
        
        DispatchQueue.main.async {
            self.currentUserProfile = profile
            self.hasCompletedProfileSetup = true
        }
        
        print("✅ [SOCIAL] Profile saved successfully")
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        Task {
            do {
                try await createOrUpdateProfile(profile)
            } catch {
                print("❌ [SOCIAL] Error updating profile: \(error)")
            }
        }
    }
    
    func checkUsernameAvailability(_ username: String) async -> Bool {
        print("🔵 [SOCIAL] Checking username availability: \(username)")
        
        do {
            let snapshot = try await db.collection("usernames").document(username.lowercased()).getDocument()
            let available = !snapshot.exists
            print("✅ [SOCIAL] Username '\(username)' available: \(available)")
            return available
        } catch {
            print("❌ [SOCIAL] Error checking username: \(error)")
            return false
        }
    }
    
    func reserveUsername(_ username: String, userId: String) async throws {
        print("🔵 [SOCIAL] Reserving username: \(username)")
        
        try await db.collection("usernames").document(username.lowercased()).setData([
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ])
        
        print("✅ [SOCIAL] Username reserved")
    }
    
    // MARK: - User Search
    
    func searchUsers(query: String) async -> [UserProfile] {
        guard !query.isEmpty else { return [] }
        
        print("🔵 [SOCIAL] Searching users: \(query)")
        
        let lowercaseQuery = query.lowercased()
        
        do {
            let snapshot = try await db.collectionGroup("profile")
                .whereField("username", isGreaterThanOrEqualTo: lowercaseQuery)
                .whereField("username", isLessThan: lowercaseQuery + "\u{f8ff}")
                .limit(to: 20)
                .getDocuments()
            
            let profiles = snapshot.documents.compactMap { doc -> UserProfile? in
                do {
                    let data = try JSONSerialization.data(withJSONObject: doc.data())
                    return try JSONDecoder().decode(UserProfile.self, from: data)
                } catch {
                    return nil
                }
            }
            
            // Filter out current user
            let currentUserId = Auth.auth().currentUser?.uid
            let filtered = profiles.filter { $0.id != currentUserId }
            
            print("✅ [SOCIAL] Found \(filtered.count) users")
            return filtered
        } catch {
            print("❌ [SOCIAL] Error searching users: \(error)")
            return []
        }
    }
    
    func fetchUserProfile(byId userId: String) async -> UserProfile? {
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("profile").document("data").getDocument()
            
            guard let data = snapshot.data() else { return nil }
            
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            return try JSONDecoder().decode(UserProfile.self, from: jsonData)
        } catch {
            print("❌ [SOCIAL] Error fetching user profile: \(error)")
            return nil
        }
    }
    
    // MARK: - Friend Requests
    
    func sendFriendRequest(to friendId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw SocialError.notAuthenticated
        }
        
        print("🔵 [SOCIAL] Sending friend request to: \(friendId)")
        
        // Check if request already exists
        let existingRequest = try await db.collection("friendships")
            .whereField("userId", isEqualTo: userId)
            .whereField("friendId", isEqualTo: friendId)
            .getDocuments()
        
        if !existingRequest.documents.isEmpty {
            throw SocialError.requestAlreadyExists
        }
        
        // Check for reverse request (they already sent us one)
        let reverseRequest = try await db.collection("friendships")
            .whereField("userId", isEqualTo: friendId)
            .whereField("friendId", isEqualTo: userId)
            .whereField("status", isEqualTo: FriendshipStatus.pending.rawValue)
            .getDocuments()
        
        if let doc = reverseRequest.documents.first {
            // Accept their request instead
            try await acceptFriendRequest(friendshipId: doc.documentID)
            return
        }
        
        // Create new friend request
        let friendship = Friendship(
            userId: userId,
            friendId: friendId,
            status: .pending
        )
        
        let data = try JSONEncoder().encode(friendship)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        try await db.collection("friendships").document(friendship.id).setData(dict)
        
        print("✅ [SOCIAL] Friend request sent")
    }
    
    func acceptFriendRequest(friendshipId: String) async throws {
        print("🔵 [SOCIAL] Accepting friend request: \(friendshipId)")
        
        try await db.collection("friendships").document(friendshipId).updateData([
            "status": FriendshipStatus.accepted.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        print("✅ [SOCIAL] Friend request accepted")
    }
    
    func declineFriendRequest(friendshipId: String) async throws {
        print("🔵 [SOCIAL] Declining friend request: \(friendshipId)")
        
        try await db.collection("friendships").document(friendshipId).delete()
        
        print("✅ [SOCIAL] Friend request declined")
    }
    
    func removeFriend(_ friendId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw SocialError.notAuthenticated
        }
        
        print("🔵 [SOCIAL] Removing friend: \(friendId)")
        
        // Find the friendship document
        let query1 = try await db.collection("friendships")
            .whereField("userId", isEqualTo: userId)
            .whereField("friendId", isEqualTo: friendId)
            .getDocuments()
        
        let query2 = try await db.collection("friendships")
            .whereField("userId", isEqualTo: friendId)
            .whereField("friendId", isEqualTo: userId)
            .getDocuments()
        
        for doc in query1.documents + query2.documents {
            try await db.collection("friendships").document(doc.documentID).delete()
        }
        
        print("✅ [SOCIAL] Friend removed")
    }
    
    func blockUser(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw SocialError.notAuthenticated
        }
        
        print("🔵 [SOCIAL] Blocking user: \(userId)")
        
        // Remove any existing friendship
        try await removeFriend(userId)
        
        // Create blocked entry
        let friendship = Friendship(
            userId: currentUserId,
            friendId: userId,
            status: .blocked
        )
        
        let data = try JSONEncoder().encode(friendship)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        try await db.collection("friendships").document(friendship.id).setData(dict)
        
        print("✅ [SOCIAL] User blocked")
    }
    
    // MARK: - Friends List
    
    private func setupFriendsListener(userId: String) {
        friendsListener?.remove()
        
        // Listen for friendships where user is either userId or friendId with accepted status
        friendsListener = db.collection("friendships")
            .whereField("status", isEqualTo: FriendshipStatus.accepted.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                Task {
                    var friendProfiles: [UserProfile] = []
                    
                    for doc in documents {
                        let data = doc.data()
                        let friendshipUserId = data["userId"] as? String ?? ""
                        let friendshipFriendId = data["friendId"] as? String ?? ""
                        
                        // Check if current user is part of this friendship
                        if friendshipUserId == userId || friendshipFriendId == userId {
                            let friendId = friendshipUserId == userId ? friendshipFriendId : friendshipUserId
                            
                            if let profile = await self.fetchUserProfile(byId: friendId) {
                                friendProfiles.append(profile)
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.friends = friendProfiles
                        print("🔄 [SOCIAL] Friends updated: \(friendProfiles.count)")
                    }
                }
            }
    }
    
    private func setupRequestsListener(userId: String) {
        requestsListener?.remove()
        
        // Listen for pending requests sent TO the current user
        requestsListener = db.collection("friendships")
            .whereField("friendId", isEqualTo: userId)
            .whereField("status", isEqualTo: FriendshipStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                Task {
                    var requests: [FriendRequest] = []
                    
                    for doc in documents {
                        do {
                            let data = try JSONSerialization.data(withJSONObject: doc.data())
                            let friendship = try JSONDecoder().decode(Friendship.self, from: data)
                            
                            if let fromUser = await self.fetchUserProfile(byId: friendship.userId) {
                                requests.append(FriendRequest(friendship: friendship, fromUser: fromUser))
                            }
                        } catch {
                            print("❌ [SOCIAL] Error decoding friend request: \(error)")
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.pendingRequests = requests
                        print("🔄 [SOCIAL] Pending requests updated: \(requests.count)")
                    }
                }
            }
    }
    
    func getFriendIds() -> [String] {
        return friends.map { $0.id }
    }
    
    func getFriendshipStatus(with userId: String) async -> FriendshipStatus? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        
        do {
            let query1 = try await db.collection("friendships")
                .whereField("userId", isEqualTo: currentUserId)
                .whereField("friendId", isEqualTo: userId)
                .getDocuments()
            
            let query2 = try await db.collection("friendships")
                .whereField("userId", isEqualTo: userId)
                .whereField("friendId", isEqualTo: currentUserId)
                .getDocuments()
            
            let docs = query1.documents + query2.documents
            
            if let doc = docs.first, let status = doc.data()["status"] as? String {
                return FriendshipStatus(rawValue: status)
            }
            
            return nil
        } catch {
            return nil
        }
    }
    
    // MARK: - Leaderboard Data
    
    func getFriendsLeaderboard(sortedBy metric: LeaderboardMetric) async -> [LeaderboardEntry] {
        var entries: [LeaderboardEntry] = []
        
        // Add current user
        if let profile = currentUserProfile {
            entries.append(LeaderboardEntry(profile: profile, isCurrentUser: true))
        }
        
        // Add friends
        for friend in friends {
            entries.append(LeaderboardEntry(profile: friend, isCurrentUser: false))
        }
        
        // Sort based on metric
        switch metric {
        case .weeklyVolume:
            // Would need to fetch weekly volume data - for now sort by totalXP
            entries.sort { $0.profile.totalXP > $1.profile.totalXP }
        case .weeklyWorkouts:
            entries.sort { $0.profile.totalWorkouts > $1.profile.totalWorkouts }
        case .streak:
            entries.sort { $0.profile.currentStreak > $1.profile.currentStreak }
        case .level:
            entries.sort { $0.profile.level > $1.profile.level }
        }
        
        // Assign ranks
        for (index, _) in entries.enumerated() {
            entries[index].rank = index + 1
        }
        
        return entries
    }
}

// MARK: - Supporting Types

enum SocialError: LocalizedError {
    case notAuthenticated
    case requestAlreadyExists
    case userNotFound
    case alreadyFriends
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action."
        case .requestAlreadyExists:
            return "A friend request already exists."
        case .userNotFound:
            return "User not found."
        case .alreadyFriends:
            return "You are already friends with this user."
        }
    }
}

enum LeaderboardMetric: String, CaseIterable {
    case weeklyVolume = "Weekly Volume"
    case weeklyWorkouts = "Weekly Workouts"
    case streak = "Streak"
    case level = "Level"
    
    var iconName: String {
        switch self {
        case .weeklyVolume: return "scalemass.fill"
        case .weeklyWorkouts: return "figure.strengthtraining.traditional"
        case .streak: return "flame.fill"
        case .level: return "star.fill"
        }
    }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let profile: UserProfile
    let isCurrentUser: Bool
    var rank: Int = 0
}
