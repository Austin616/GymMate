//
//  FeedManager.swift
//  fit-texas
//
//  Created by GymMate
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
internal import Combine

class FeedManager: ObservableObject {
    static let shared = FeedManager()
    
    @Published var feedPosts: [FeedPost] = []
    @Published var suggestedUsers: [UserProfile] = []
    @Published var isLoading: Bool = false
    @Published var hasMorePosts: Bool = true
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var feedListener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    
    private init() {
        print("🔵 [FEED] Initializing FeedManager...")
        setupAuthListener()
    }
    
    deinit {
        feedListener?.remove()
    }
    
    // MARK: - Auth Listener
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                self?.setupCampusFeedListener()
                self?.loadSuggestedUsers()
            } else {
                // Remove listener and clear data on sign out
                print("🧹 [FEED] Removing feed listener")
                self?.feedListener?.remove()
                self?.feedListener = nil
                self?.feedPosts = []
                self?.suggestedUsers = []
                self?.lastDocument = nil
            }
        }
    }
    
    // MARK: - Feed Operations (Campus-wide)
    
    private func setupCampusFeedListener() {
        feedListener?.remove()
        
        // Listen to ALL posts (campus-wide feed)
        feedListener = db.collection("feed")
            .order(by: "createdAt", descending: true)
            .limit(to: pageSize)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [FEED] Error listening to feed: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.lastDocument = documents.last
                self.hasMorePosts = documents.count >= self.pageSize
                
                Task {
                    await self.processFeedDocuments(documents)
                }
            }
    }
    
    func fetchFeed(refresh: Bool = false) async {
        if refresh {
            lastDocument = nil
            hasMorePosts = true
        }
        
        guard hasMorePosts else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            var query = db.collection("feed")
                .order(by: "createdAt", descending: true)
                .limit(to: pageSize)
            
            if let lastDoc = lastDocument {
                query = query.start(afterDocument: lastDoc)
            }
            
            let snapshot = try await query.getDocuments()
            
            lastDocument = snapshot.documents.last
            hasMorePosts = snapshot.documents.count >= pageSize
            
            await processFeedDocuments(snapshot.documents, append: !refresh)
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            print("❌ [FEED] Error fetching feed: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Suggested Users
    
    func loadSuggestedUsers() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        print("🔵 [FEED] Loading suggested users...")
        
        // Get users who have posted recently (active users)
        db.collection("feed")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                // Get unique user IDs from recent posts
                var userIds = Set<String>()
                for doc in documents {
                    if let userId = doc.data()["userId"] as? String {
                        userIds.insert(userId)
                    }
                }
                
                // Remove current user and existing friends
                userIds.remove(currentUserId)
                let friendIds = Set(SocialManager.shared.getFriendIds())
                userIds.subtract(friendIds)
                
                // Fetch profiles for these users
                Task {
                    var profiles: [UserProfile] = []
                    for userId in Array(userIds.prefix(10)) {
                        if let profile = await SocialManager.shared.fetchUserProfile(byId: userId) {
                            profiles.append(profile)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.suggestedUsers = profiles
                        print("✅ [FEED] Loaded \(profiles.count) suggested users")
                    }
                }
            }
    }
    
    private func processFeedDocuments(_ documents: [DocumentSnapshot], append: Bool = false) async {
        var posts: [FeedPost] = []
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        
        for doc in documents {
            guard let data = doc.data() else { continue }
            
            do {
                var post = try doc.data(as: FeedPost.self)
                
                // EXCLUDE user's own posts from the feed
                if post.userId == currentUserId {
                    continue
                }
                
                // Check if current user has liked this post
                let likeDoc = try? await db.collection("feed").document(post.id)
                    .collection("likes").document(currentUserId).getDocument()
                post.isLikedByCurrentUser = likeDoc?.exists ?? false
                
                posts.append(post)
            } catch {
                print("❌ [FEED] Error decoding post: \(error)")
            }
        }
        
        DispatchQueue.main.async {
            if append {
                self.feedPosts.append(contentsOf: posts)
            } else {
                self.feedPosts = posts
            }
            print("🔄 [FEED] Feed updated: \(self.feedPosts.count) posts")
        }
    }
    
    // MARK: - Share Workout
    
    func shareWorkout(_ workout: SavedWorkout, caption: String?, duration: TimeInterval?) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let profile = SocialManager.shared.currentUserProfile else {
            throw FeedError.notAuthenticated
        }
        
        print("🔵 [FEED] Sharing workout: \(workout.name)")
        
        // Create exercise summaries
        let exerciseSummaries = workout.exercises.map { exercise -> ExerciseSummary in
            let bestSet = exercise.sets.max { set1, set2 in
                let weight1 = Double(set1.weight) ?? 0
                let weight2 = Double(set2.weight) ?? 0
                return weight1 < weight2
            }
            
            var bestSetString: String? = nil
            if let best = bestSet,
               let weight = Double(best.weight), weight > 0,
               let reps = Int(best.reps), reps > 0 {
                bestSetString = "\(Int(weight))kg x \(reps)"
            }
            
            return ExerciseSummary(
                name: exercise.name,
                setCount: exercise.sets.count,
                bestSet: bestSetString
            )
        }
        
        let post = FeedPost(
            userId: userId,
            userDisplayName: profile.displayName,
            userProfileImageURL: profile.profileImageURL,
            workoutId: workout.id.uuidString,
            workoutName: workout.name,
            workoutDate: workout.date,
            exerciseCount: workout.exercises.count,
            totalSets: workout.totalSets,
            totalVolume: workout.totalVolume,
            duration: duration,
            caption: caption,
            exerciseSummaries: exerciseSummaries
        )
        
        try db.collection("feed").document(post.id).setData(from: post)
        
        print("✅ [FEED] Workout shared successfully")
    }
    
    // MARK: - Like/Unlike
    
    /// Check if current user has liked a post
    func hasLikedPost(_ postId: String) async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }
        
        do {
            let doc = try await db.collection("feed").document(postId)
                .collection("likes").document(userId).getDocument()
            return doc.exists
        } catch {
            return false
        }
    }
    
    func likePost(_ postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FeedError.notAuthenticated
        }
        
        // Check if already liked
        let alreadyLiked = await hasLikedPost(postId)
        if alreadyLiked {
            print("⚠️ [FEED] Post already liked")
            return
        }
        
        print("🔵 [FEED] Liking post: \(postId)")
        
        let like = PostLike(postId: postId, userId: userId)
        
        let batch = db.batch()
        
        // Add like document
        let likeRef = db.collection("feed").document(postId).collection("likes").document(userId)
        try batch.setData(from: like, forDocument: likeRef)
        
        // Increment likes count
        let postRef = db.collection("feed").document(postId)
        batch.updateData(["likesCount": FieldValue.increment(Int64(1))], forDocument: postRef)
        
        try await batch.commit()
        
        // Update local state
        DispatchQueue.main.async {
            if let index = self.feedPosts.firstIndex(where: { $0.id == postId }) {
                self.feedPosts[index].likesCount += 1
                self.feedPosts[index].isLikedByCurrentUser = true
            }
        }
        
        print("✅ [FEED] Post liked")
    }
    
    func unlikePost(_ postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FeedError.notAuthenticated
        }
        
        // Check if actually liked
        let isLiked = await hasLikedPost(postId)
        if !isLiked {
            print("⚠️ [FEED] Post not liked, cannot unlike")
            return
        }
        
        print("🔵 [FEED] Unliking post: \(postId)")
        
        let batch = db.batch()
        
        // Remove like document
        let likeRef = db.collection("feed").document(postId).collection("likes").document(userId)
        batch.deleteDocument(likeRef)
        
        // Decrement likes count
        let postRef = db.collection("feed").document(postId)
        batch.updateData(["likesCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
        
        try await batch.commit()
        
        // Update local state
        DispatchQueue.main.async {
            if let index = self.feedPosts.firstIndex(where: { $0.id == postId }) {
                self.feedPosts[index].likesCount = max(0, self.feedPosts[index].likesCount - 1)
                self.feedPosts[index].isLikedByCurrentUser = false
            }
        }
        
        print("✅ [FEED] Post unliked")
    }
    
    func toggleLike(for postId: String) async throws {
        // Check actual like status from Firestore
        let isLiked = await hasLikedPost(postId)
        
        if isLiked {
            try await unlikePost(postId)
        } else {
            try await likePost(postId)
        }
    }
    
    // MARK: - Comments
    
    func fetchComments(for postId: String) async -> [PostComment] {
        print("🔵 [FEED] Fetching comments for post: \(postId)")
        
        do {
            let snapshot = try await db.collection("feed").document(postId)
                .collection("comments")
                .order(by: "createdAt", descending: false)
                .getDocuments()
            
            let comments = snapshot.documents.compactMap { doc -> PostComment? in
                try? doc.data(as: PostComment.self)
            }
            
            print("✅ [FEED] Fetched \(comments.count) comments")
            return comments
        } catch {
            print("❌ [FEED] Error fetching comments: \(error)")
            return []
        }
    }
    
    func addComment(to postId: String, text: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let profile = SocialManager.shared.currentUserProfile else {
            throw FeedError.notAuthenticated
        }
        
        print("🔵 [FEED] Adding comment to post: \(postId)")
        
        let comment = PostComment(
            postId: postId,
            userId: userId,
            userDisplayName: profile.displayName,
            userProfileImageURL: profile.profileImageURL,
            text: text
        )
        
        let batch = db.batch()
        
        // Add comment document
        let commentRef = db.collection("feed").document(postId).collection("comments").document(comment.id)
        try batch.setData(from: comment, forDocument: commentRef)
        
        // Increment comments count
        let postRef = db.collection("feed").document(postId)
        batch.updateData(["commentsCount": FieldValue.increment(Int64(1))], forDocument: postRef)
        
        try await batch.commit()
        
        // Update local state
        DispatchQueue.main.async {
            if let index = self.feedPosts.firstIndex(where: { $0.id == postId }) {
                self.feedPosts[index].commentsCount += 1
            }
        }
        
        print("✅ [FEED] Comment added")
    }
    
    func deleteComment(_ commentId: String, from postId: String) async throws {
        print("🔵 [FEED] Deleting comment: \(commentId)")
        
        let batch = db.batch()
        
        // Delete comment document
        let commentRef = db.collection("feed").document(postId).collection("comments").document(commentId)
        batch.deleteDocument(commentRef)
        
        // Decrement comments count
        let postRef = db.collection("feed").document(postId)
        batch.updateData(["commentsCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
        
        try await batch.commit()
        
        // Update local state
        DispatchQueue.main.async {
            if let index = self.feedPosts.firstIndex(where: { $0.id == postId }) {
                self.feedPosts[index].commentsCount = max(0, self.feedPosts[index].commentsCount - 1)
            }
        }
        
        print("✅ [FEED] Comment deleted")
    }
    
    // MARK: - Delete Post
    
    func deletePost(_ postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FeedError.notAuthenticated
        }
        
        print("🔵 [FEED] Deleting post: \(postId)")
        
        // Verify ownership
        let postDoc = try await db.collection("feed").document(postId).getDocument()
        guard let postUserId = postDoc.data()?["userId"] as? String, postUserId == userId else {
            throw FeedError.notAuthorized
        }
        
        // Delete post and subcollections
        try await db.collection("feed").document(postId).delete()
        
        // Update local state
        DispatchQueue.main.async {
            self.feedPosts.removeAll { $0.id == postId }
        }
        
        print("✅ [FEED] Post deleted")
    }
    
    // MARK: - Fetch Single Post
    
    func fetchPost(_ postId: String) async -> FeedPost? {
        do {
            let doc = try await db.collection("feed").document(postId).getDocument()
            var post = try doc.data(as: FeedPost.self)
            
            // Check if current user has liked this post
            if let userId = Auth.auth().currentUser?.uid {
                let likeDoc = try? await db.collection("feed").document(postId)
                    .collection("likes").document(userId).getDocument()
                post.isLikedByCurrentUser = likeDoc?.exists ?? false
            }
            
            return post
        } catch {
            print("❌ [FEED] Error fetching post: \(error)")
            return nil
        }
    }
    
    // MARK: - User's Posts
    
    func fetchUserPosts(userId: String) async -> [FeedPost] {
        do {
            let snapshot = try await db.collection("feed")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            let posts = snapshot.documents.compactMap { doc -> FeedPost? in
                try? doc.data(as: FeedPost.self)
            }
            
            return posts
        } catch {
            print("❌ [FEED] Error fetching user posts: \(error)")
            return []
        }
    }
    
    // MARK: - Refresh Feed
    
    func refreshFeed() {
        setupCampusFeedListener()
    }
}

// MARK: - Supporting Types

enum FeedError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case postNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action."
        case .notAuthorized:
            return "You are not authorized to perform this action."
        case .postNotFound:
            return "Post not found."
        }
    }
}
