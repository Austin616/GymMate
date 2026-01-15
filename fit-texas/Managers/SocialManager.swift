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
    @Published var isCheckingProfile: Bool = true  // Start true until we know
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
                self?.isCheckingProfile = true
                self?.fetchUserProfile(userId: user.uid)
                self?.setupFriendsListener(userId: user.uid)
                self?.setupRequestsListener(userId: user.uid)
            } else {
                // Remove listeners when user logs out
                self?.removeAllListeners()
                DispatchQueue.main.async {
                    self?.currentUserProfile = nil
                    self?.friends = []
                    self?.pendingRequests = []
                    self?.hasCompletedProfileSetup = false
                    self?.isCheckingProfile = false
                }
            }
        }
    }
    
    private func removeAllListeners() {
        print("🧹 [SOCIAL] Removing all Firestore listeners")
        friendsListener?.remove()
        friendsListener = nil
        requestsListener?.remove()
        requestsListener = nil
    }
    
    // MARK: - Profile Management
    
    func fetchUserProfile(userId: String) {
        print("🔵 [SOCIAL] Fetching profile for user: \(userId)")
        
        db.collection("users").document(userId).collection("profile").document("data")
            .getDocument { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isCheckingProfile = false
                }
                
                if let error = error {
                    print("❌ [SOCIAL] Error fetching profile: \(error)")
                    DispatchQueue.main.async {
                        self?.hasCompletedProfileSetup = false
                    }
                    return
                }
                
                guard let data = snapshot?.data(), !data.isEmpty else {
                    print("ℹ️ [SOCIAL] No profile found for user")
                    DispatchQueue.main.async {
                        self?.hasCompletedProfileSetup = false
                    }
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
                    DispatchQueue.main.async {
                        self?.hasCompletedProfileSetup = false
                    }
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
    
    func getAllUsers() async -> [UserProfile] {
        print("🔵 [SOCIAL] Fetching all users...")
        
        let currentUserId = Auth.auth().currentUser?.uid
        
        do {
            // Use the usernames collection to find all users (this is guaranteed to exist for each registered user)
            let usernamesSnapshot = try await db.collection("usernames").getDocuments()
            
            print("🔵 [SOCIAL] Found \(usernamesSnapshot.documents.count) usernames")
            
            var profiles: [UserProfile] = []
            
            for usernameDoc in usernamesSnapshot.documents {
                guard let userId = usernameDoc.data()["userId"] as? String else { continue }
                
                // Skip current user
                if userId == currentUserId { continue }
                
                // Fetch profile for this user
                let profileSnapshot = try await db.collection("users")
                    .document(userId)
                    .collection("profile")
                    .document("data")
                    .getDocument()
                
                guard let data = profileSnapshot.data() else {
                    print("⚠️ [SOCIAL] No profile data for user: \(userId)")
                    continue
                }
                
                let username = data["username"] as? String ?? usernameDoc.documentID
                let displayName = data["displayName"] as? String ?? username
                
                let profile = UserProfile(
                    id: userId,
                    username: username,
                    displayName: displayName,
                    bio: data["bio"] as? String ?? "",
                    totalXP: data["totalXP"] as? Int ?? 0,
                    level: data["level"] as? Int ?? 1,
                    currentStreak: data["currentStreak"] as? Int ?? 0,
                    longestStreak: data["longestStreak"] as? Int ?? 0,
                    totalWorkouts: data["totalWorkouts"] as? Int ?? 0,
                    followersCount: data["followersCount"] as? Int ?? 0,
                    followingCount: data["followingCount"] as? Int ?? 0,
                    postsCount: data["postsCount"] as? Int ?? 0,
                    isCurrentlyWorkingOut: data["isCurrentlyWorkingOut"] as? Bool ?? false,
                    currentWorkoutStartTime: (data["currentWorkoutStartTime"] as? Timestamp)?.dateValue(),
                    joinedDate: (data["joinedDate"] as? Timestamp)?.dateValue() ?? Date(),
                    isPublic: data["isPublic"] as? Bool ?? true
                )
                
                profiles.append(profile)
                print("   ✅ Found user: @\(username)")
            }
            
            print("✅ [SOCIAL] Found \(profiles.count) users total")
            return profiles
        } catch {
            print("❌ [SOCIAL] Error fetching users: \(error)")
            return []
        }
    }
    
    func searchUsers(query: String) async -> [UserProfile] {
        guard !query.isEmpty else { return [] }
        
        print("🔵 [SOCIAL] Searching users: \(query)")
        
        let lowercaseQuery = query.lowercased()
        let currentUserId = Auth.auth().currentUser?.uid
        
        do {
            // Get all users and filter client-side (more reliable than collectionGroup)
            let usersSnapshot = try await db.collection("users").getDocuments()
            
            var matchingProfiles: [UserProfile] = []
            
            for userDoc in usersSnapshot.documents {
                let userId = userDoc.documentID
                
                // Skip current user
                if userId == currentUserId { continue }
                
                // Fetch profile for each user
                let profileSnapshot = try await db.collection("users")
                    .document(userId)
                    .collection("profile")
                    .document("data")
                    .getDocument()
                
                guard let data = profileSnapshot.data() else { continue }
                
                // Parse profile manually to avoid decoding issues
                let username = data["username"] as? String ?? ""
                let displayName = data["displayName"] as? String ?? ""
                
                // Check if matches query
                if username.lowercased().contains(lowercaseQuery) ||
                   displayName.lowercased().contains(lowercaseQuery) {
                    
                    let profile = UserProfile(
                        id: userId,
                        username: username,
                        displayName: displayName,
                        bio: data["bio"] as? String ?? "",
                        totalXP: data["totalXP"] as? Int ?? 0,
                        level: data["level"] as? Int ?? 1,
                        currentStreak: data["currentStreak"] as? Int ?? 0,
                        longestStreak: data["longestStreak"] as? Int ?? 0,
                        totalWorkouts: data["totalWorkouts"] as? Int ?? 0,
                        followersCount: data["followersCount"] as? Int ?? 0,
                        followingCount: data["followingCount"] as? Int ?? 0,
                        postsCount: data["postsCount"] as? Int ?? 0,
                        isCurrentlyWorkingOut: data["isCurrentlyWorkingOut"] as? Bool ?? false,
                        currentWorkoutStartTime: (data["currentWorkoutStartTime"] as? Timestamp)?.dateValue(),
                        joinedDate: (data["joinedDate"] as? Timestamp)?.dateValue() ?? Date(),
                        isPublic: data["isPublic"] as? Bool ?? true
                    )
                    
                    matchingProfiles.append(profile)
                    print("   Found: @\(username) - \(displayName)")
                }
            }
            
            print("✅ [SOCIAL] Found \(matchingProfiles.count) users matching '\(query)'")
            return matchingProfiles
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
    
    // MARK: - Follow System
    
    /// Follow a public user directly, or send a follow request for private users
    func followUser(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw SocialError.notAuthenticated
        }
        
        // Check if target user is public or private
        guard let targetProfile = await fetchUserProfile(byId: userId) else {
            throw SocialError.userNotFound
        }
        
        if targetProfile.isPublic {
            // Public profile - follow directly
            try await performFollow(currentUserId: currentUserId, targetUserId: userId)
        } else {
            // Private profile - send follow request
            try await sendFollowRequest(to: userId)
        }
    }
    
    /// Directly follow a user (for public profiles or when request is accepted)
    func performFollow(currentUserId: String, targetUserId: String) async throws {
        print("🔵 [SOCIAL] Following user: \(targetUserId)")
        
        let followId = "\(currentUserId)_\(targetUserId)"
        
        let batch = db.batch()
        
        // Add follow document
        let followRef = db.collection("follows").document(followId)
        batch.setData([
            "followerId": currentUserId,
            "followingId": targetUserId,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: followRef)
        
        // Increment follower count for target user
        let targetProfileRef = db.collection("users").document(targetUserId).collection("profile").document("data")
        batch.updateData(["followersCount": FieldValue.increment(Int64(1))], forDocument: targetProfileRef)
        
        // Increment following count for current user
        let currentProfileRef = db.collection("users").document(currentUserId).collection("profile").document("data")
        batch.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: currentProfileRef)
        
        try await batch.commit()
        
        // Update local profile
        DispatchQueue.main.async {
            if var profile = self.currentUserProfile {
                profile.followingCount += 1
                self.currentUserProfile = profile
            }
        }
        
        print("✅ [SOCIAL] Now following user")
    }
    
    /// Send a follow request to a private user
    func sendFollowRequest(to userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw SocialError.notAuthenticated
        }
        
        print("🔵 [SOCIAL] Sending follow request to: \(userId)")
        
        let requestId = "\(currentUserId)_\(userId)"
        
        // Check if request already exists
        let existingRequest = try await db.collection("followRequests").document(requestId).getDocument()
        if existingRequest.exists {
            print("⚠️ [SOCIAL] Follow request already exists")
            return
        }
        
        try await db.collection("followRequests").document(requestId).setData([
            "fromUserId": currentUserId,
            "toUserId": userId,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ])
        
        print("✅ [SOCIAL] Follow request sent")
    }
    
    /// Accept a follow request
    func acceptFollowRequest(fromUserId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw SocialError.notAuthenticated
        }
        
        print("🔵 [SOCIAL] Accepting follow request from: \(fromUserId)")
        
        let requestId = "\(fromUserId)_\(currentUserId)"
        
        // Delete the request
        try await db.collection("followRequests").document(requestId).delete()
        
        // Create the follow relationship
        try await performFollow(currentUserId: fromUserId, targetUserId: currentUserId)
        
        print("✅ [SOCIAL] Follow request accepted")
    }
    
    /// Decline a follow request
    func declineFollowRequest(fromUserId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw SocialError.notAuthenticated
        }
        
        print("🔵 [SOCIAL] Declining follow request from: \(fromUserId)")
        
        let requestId = "\(fromUserId)_\(currentUserId)"
        try await db.collection("followRequests").document(requestId).delete()
        
        print("✅ [SOCIAL] Follow request declined")
    }
    
    /// Check if a follow request is pending
    func hasRequestedFollow(_ userId: String) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        
        let requestId = "\(currentUserId)_\(userId)"
        
        do {
            let doc = try await db.collection("followRequests").document(requestId).getDocument()
            return doc.exists
        } catch {
            return false
        }
    }
    
    /// Get pending follow requests for current user
    func getFollowRequests() async -> [UserProfile] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        do {
            let snapshot = try await db.collection("followRequests")
                .whereField("toUserId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            
            var profiles: [UserProfile] = []
            
            for doc in snapshot.documents {
                let fromUserId = doc.data()["fromUserId"] as? String ?? ""
                if let profile = await fetchUserProfile(byId: fromUserId) {
                    profiles.append(profile)
                }
            }
            
            return profiles
        } catch {
            print("❌ [SOCIAL] Error fetching follow requests: \(error)")
            return []
        }
    }
    
    func unfollowUser(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw SocialError.notAuthenticated
        }
        
        print("🔵 [SOCIAL] Unfollowing user: \(userId)")
        
        let followId = "\(currentUserId)_\(userId)"
        
        // Check if follow exists
        let followDoc = try await db.collection("follows").document(followId).getDocument()
        guard followDoc.exists else {
            print("⚠️ [SOCIAL] Not following this user")
            return
        }
        
        let batch = db.batch()
        
        // Remove follow document
        let followRef = db.collection("follows").document(followId)
        batch.deleteDocument(followRef)
        
        // Decrement follower count for target user
        let targetProfileRef = db.collection("users").document(userId).collection("profile").document("data")
        batch.updateData(["followersCount": FieldValue.increment(Int64(-1))], forDocument: targetProfileRef)
        
        // Decrement following count for current user
        let currentProfileRef = db.collection("users").document(currentUserId).collection("profile").document("data")
        batch.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: currentProfileRef)
        
        try await batch.commit()
        
        // Update local profile
        DispatchQueue.main.async {
            if var profile = self.currentUserProfile {
                profile.followingCount = max(0, profile.followingCount - 1)
                self.currentUserProfile = profile
            }
        }
        
        print("✅ [SOCIAL] Unfollowed user")
    }
    
    /// Cancel a pending follow request
    func cancelFollowRequest(to userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw SocialError.notAuthenticated
        }
        
        print("🔵 [SOCIAL] Cancelling follow request to: \(userId)")
        
        let requestId = "\(currentUserId)_\(userId)"
        try await db.collection("followRequests").document(requestId).delete()
        
        print("✅ [SOCIAL] Follow request cancelled")
    }
    
    func isFollowing(_ userId: String) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        
        let followId = "\(currentUserId)_\(userId)"
        
        do {
            let doc = try await db.collection("follows").document(followId).getDocument()
            return doc.exists
        } catch {
            return false
        }
    }
    
    /// Check if another user is following us
    func isFollowedBy(_ userId: String) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        
        let followId = "\(userId)_\(currentUserId)"
        
        do {
            let doc = try await db.collection("follows").document(followId).getDocument()
            return doc.exists
        } catch {
            return false
        }
    }
    
    /// Check if two users are mutual followers (friends)
    func areFriends(with userId: String) async -> Bool {
        let following = await isFollowing(userId)
        let followedBy = await isFollowedBy(userId)
        return following && followedBy
    }
    
    func getFollowers(for userId: String) async -> [UserProfile] {
        do {
            let snapshot = try await db.collection("follows")
                .whereField("followingId", isEqualTo: userId)
                .limit(to: 100)
                .getDocuments()
            
            var profiles: [UserProfile] = []
            
            for doc in snapshot.documents {
                let followerId = doc.data()["followerId"] as? String ?? ""
                if let profile = await fetchUserProfile(byId: followerId) {
                    profiles.append(profile)
                }
            }
            
            return profiles
        } catch {
            print("❌ [SOCIAL] Error fetching followers: \(error)")
            return []
        }
    }
    
    func getFollowing(for userId: String) async -> [UserProfile] {
        do {
            let snapshot = try await db.collection("follows")
                .whereField("followerId", isEqualTo: userId)
                .limit(to: 100)
                .getDocuments()
            
            var profiles: [UserProfile] = []
            
            for doc in snapshot.documents {
                let followingId = doc.data()["followingId"] as? String ?? ""
                if let profile = await fetchUserProfile(byId: followingId) {
                    profiles.append(profile)
                }
            }
            
            return profiles
        } catch {
            print("❌ [SOCIAL] Error fetching following: \(error)")
            return []
        }
    }
    
    // MARK: - Workout Status
    
    func updateWorkoutStatus(isWorkingOut: Bool) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var data: [String: Any] = ["isCurrentlyWorkingOut": isWorkingOut]
        
        if isWorkingOut {
            data["currentWorkoutStartTime"] = FieldValue.serverTimestamp()
        } else {
            data["currentWorkoutStartTime"] = NSNull()
        }
        
        do {
            try await db.collection("users").document(userId).collection("profile").document("data")
                .updateData(data)
            
            if var profile = currentUserProfile {
                profile.isCurrentlyWorkingOut = isWorkingOut
                profile.currentWorkoutStartTime = isWorkingOut ? Date() : nil
                DispatchQueue.main.async {
                    self.currentUserProfile = profile
                }
            }
        } catch {
            print("❌ [SOCIAL] Error updating workout status: \(error)")
        }
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
