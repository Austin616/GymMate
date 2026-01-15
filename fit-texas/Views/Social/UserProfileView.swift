//
//  UserProfileView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI
import FirebaseAuth

struct UserProfileView: View {
    let userId: String
    @StateObject private var socialManager = SocialManager.shared
    @StateObject private var feedManager = FeedManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var userProfile: UserProfile?
    @State private var userPosts: [FeedPost] = []
    @State private var isLoading = true
    @State private var isFollowing = false
    @State private var isFollowedBy = false
    @State private var hasRequestedFollow = false
    @State private var isPerformingAction = false
    @State private var selectedTab = 0
    @State private var showFollowers = false
    @State private var showFollowing = false
    
    private var isOwnProfile: Bool {
        userId == Auth.auth().currentUser?.uid
    }
    
    private var isPrivateProfile: Bool {
        !(userProfile?.isPublic ?? true)
    }
    
    private var areFriends: Bool {
        isFollowing && isFollowedBy
    }
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let profile = userProfile {
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header
                        profileHeader(profile: profile)
                        
                        // Stats Row
                        statsRow(profile: profile)
                            .padding(.top, 16)
                        
                        // Bio Section
                        bioSection(profile: profile)
                            .padding(.top, 12)
                        
                        // Action Button
                        actionButton(profile: profile)
                            .padding(.top, 16)
                            .padding(.horizontal)
                        
                        // Currently Working Out
                        if profile.isCurrentlyWorkingOut {
                            workingOutBanner(profile: profile)
                                .padding(.top, 16)
                                .padding(.horizontal)
                        }
                        
                        // Content Tabs
                        contentTabs
                            .padding(.top, 20)
                        
                        // Content
                        contentView(profile: profile)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, 100)
                }
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "person.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("User Not Found")
                        .font(.headline)
                    
                    Spacer()
                }
            }
        }
        .navigationTitle(userProfile?.username ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            Group {
                NavigationLink(
                    destination: FollowListView(userId: userId, mode: .followers),
                    isActive: $showFollowers
                ) { EmptyView() }
                
                NavigationLink(
                    destination: FollowListView(userId: userId, mode: .following),
                    isActive: $showFollowing
                ) { EmptyView() }
            }
            .hidden()
        )
        .task {
            await loadProfile()
        }
    }
    
    // MARK: - Profile Header
    
    private func profileHeader(profile: UserProfile) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.utOrange, Color.utOrange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        Text(String(profile.displayName.prefix(1)).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                // Level Badge
                ZStack {
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .fill(Color.utOrange)
                        .frame(width: 26, height: 26)
                    
                    Text("\(profile.level)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 4, y: 4)
                
                // Online indicator
                if profile.isCurrentlyWorkingOut {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 3)
                        )
                        .offset(x: -4, y: 4)
                }
            }
            
            Text(profile.displayName)
                .font(.title3)
                .fontWeight(.bold)
            
            Text("@\(profile.username)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Stats Row
    
    private func statsRow(profile: UserProfile) -> some View {
        HStack(spacing: 0) {
            ProfileStatButton(value: "\(profile.postsCount)", label: "Posts") {
                selectedTab = 0
            }
            
            ProfileStatButton(value: "\(profile.followersCount)", label: "Followers") {
                showFollowers = true
            }
            
            ProfileStatButton(value: "\(profile.followingCount)", label: "Following") {
                showFollowing = true
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Bio Section
    
    private func bioSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !profile.bio.isEmpty {
                Text(profile.bio)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            
            // Level & Stats
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.utOrange)
                    .font(.caption)
                
                Text("Level \(profile.level)")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("\(profile.totalXP) XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("\(profile.totalWorkouts) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Streak
            if profile.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("\(profile.currentStreak) day streak")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Action Button
    
    private func actionButton(profile: UserProfile) -> some View {
        Group {
            if isOwnProfile {
                // Edit Profile button for own profile
                Button(action: {}) {
                    Text("Edit Profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            } else if areFriends {
                // Mutual follow - Friends (can unfollow)
                Button(action: unfollowUser) {
                    HStack(spacing: 8) {
                        if isPerformingAction {
                            ProgressView()
                                .tint(.green)
                        } else {
                            Image(systemName: "person.2.fill")
                            Text("Friends")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(isPerformingAction)
            } else if isFollowing {
                // We follow them (can unfollow)
                Button(action: unfollowUser) {
                    HStack(spacing: 8) {
                        if isPerformingAction {
                            ProgressView()
                                .tint(.primary)
                        } else {
                            Text("Following")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                .disabled(isPerformingAction)
            } else if hasRequestedFollow {
                // Requested - waiting for approval (private profile)
                Button(action: cancelFollowRequest) {
                    HStack(spacing: 8) {
                        if isPerformingAction {
                            ProgressView()
                                .tint(.secondary)
                        } else {
                            Text("Requested")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                .disabled(isPerformingAction)
            } else {
                // Follow button (or Request for private)
                Button(action: followUser) {
                    HStack(spacing: 8) {
                        if isPerformingAction {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(isPrivateProfile ? "Request" : "Follow")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.utOrange)
                    .cornerRadius(8)
                }
                .disabled(isPerformingAction)
            }
        }
    }
    
    // MARK: - Working Out Banner
    
    private func workingOutBanner(profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.4), lineWidth: 4)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Currently Working Out")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let startTime = profile.currentWorkoutStartTime {
                    Text("Started \(timeAgo(from: startTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "figure.strengthtraining.traditional")
                .foregroundColor(.utOrange)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Content Tabs
    
    private var contentTabs: some View {
        HStack(spacing: 0) {
            ProfileTabButton(icon: "square.grid.3x3.fill", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            ProfileTabButton(icon: "list.bullet", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
        }
        .overlay(
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5),
            alignment: .top
        )
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private func contentView(profile: UserProfile) -> some View {
        if profile.isPublic || isFollowing || isOwnProfile {
            if selectedTab == 0 {
                workoutGridView
            } else {
                workoutListView
            }
        } else {
            // Private profile
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                
                Text("This Account is Private")
                    .font(.headline)
                
                Text("Follow this account to see their workouts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 60)
        }
    }
    
    // MARK: - Workout Grid View
    
    private var workoutGridView: some View {
        Group {
            if userPosts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "camera")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No Posts Yet")
                        .font(.headline)
                }
                .padding(.vertical, 60)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 2) {
                    ForEach(userPosts) { post in
                        NavigationLink(destination: PostDetailView(post: post)) {
                            PostGridCell(post: post)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Workout List View
    
    private var workoutListView: some View {
        VStack(spacing: 12) {
            ForEach(userPosts) { post in
                NavigationLink(destination: PostDetailView(post: post)) {
                    UserActivityCard(post: post)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func loadProfile() async {
        isLoading = true
        
        userProfile = nil
        userPosts = []
        isFollowing = false
        isFollowedBy = false
        hasRequestedFollow = false
        
        userProfile = await socialManager.fetchUserProfile(byId: userId)
        isFollowing = await socialManager.isFollowing(userId)
        isFollowedBy = await socialManager.isFollowedBy(userId)
        
        // Check if we've sent a follow request (for private profiles)
        if !isFollowing {
            hasRequestedFollow = await socialManager.hasRequestedFollow(userId)
        }
        
        userPosts = await feedManager.fetchUserPosts(userId: userId)
        
        isLoading = false
    }
    
    private func followUser() {
        isPerformingAction = true
        
        Task {
            do {
                try await socialManager.followUser(userId)
                await MainActor.run {
                    // For public profiles, we're now following
                    // For private profiles, we've sent a request
                    if userProfile?.isPublic == true {
                        isFollowing = true
                        if var profile = userProfile {
                            profile.followersCount += 1
                            userProfile = profile
                        }
                    } else {
                        hasRequestedFollow = true
                    }
                }
            } catch {
                print("Error following user: \(error)")
            }
            
            await MainActor.run {
                isPerformingAction = false
            }
        }
    }
    
    private func unfollowUser() {
        isPerformingAction = true
        
        Task {
            do {
                try await socialManager.unfollowUser(userId)
                await MainActor.run {
                    isFollowing = false
                    if var profile = userProfile {
                        profile.followersCount = max(0, profile.followersCount - 1)
                        userProfile = profile
                    }
                }
            } catch {
                print("Error unfollowing user: \(error)")
            }
            
            await MainActor.run {
                isPerformingAction = false
            }
        }
    }
    
    private func cancelFollowRequest() {
        isPerformingAction = true
        
        Task {
            do {
                try await socialManager.cancelFollowRequest(to: userId)
                await MainActor.run {
                    hasRequestedFollow = false
                }
            } catch {
                print("Error cancelling follow request: \(error)")
            }
            
            await MainActor.run {
                isPerformingAction = false
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Post Grid Cell

struct PostGridCell: View {
    let post: FeedPost
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.utOrange.opacity(0.3), Color.utOrange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 4) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(.utOrange)
                
                Text("\(post.exerciseCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("exercises")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Likes overlay
            VStack {
                Spacer()
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                        Text("\(post.likesCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)
                    
                    Spacer()
                }
                .padding(4)
            }
        }
        .aspectRatio(1, contentMode: .fill)
    }
}

// MARK: - User Activity Card

struct UserActivityCard: View {
    let post: FeedPost
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: post.createdAt, relativeTo: Date())
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(post.workoutName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption2)
                        Text("\(post.exerciseCount)")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "number.circle")
                            .font(.caption2)
                        Text("\(post.totalSets)")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass")
                            .font(.caption2)
                        Text("\(Int(post.totalVolume)) kg")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                        Text("\(post.likesCount)")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: "test123")
    }
}
