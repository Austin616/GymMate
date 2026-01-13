//
//  UserProfileView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI

struct UserProfileView: View {
    let userId: String
    @StateObject private var socialManager = SocialManager.shared
    @StateObject private var feedManager = FeedManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var userProfile: UserProfile?
    @State private var userPosts: [FeedPost] = []
    @State private var isLoading = true
    @State private var friendshipStatus: FriendshipStatus?
    @State private var isPerformingAction = false
    
    private var isFriend: Bool {
        socialManager.friends.contains { $0.id == userId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            CustomTabHeader(
                title: userProfile?.displayName ?? "Profile",
                leadingButton: AnyView(
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body)
                                .fontWeight(.semibold)
                            Text("Back")
                        }
                        .foregroundColor(.utOrange)
                    }
                ),
                isSubScreen: true
            )
            
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let profile = userProfile {
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.utOrange, Color.utOrange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(String(profile.displayName.prefix(1)).uppercased())
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color.utOrange.opacity(0.3), radius: 12, x: 0, y: 4)
                            
                            VStack(spacing: 4) {
                                Text(profile.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("@\(profile.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if !profile.bio.isEmpty {
                                    Text(profile.bio)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 4)
                                }
                            }
                            
                            // Level Badge
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.utOrange)
                                Text("Level \(profile.level)")
                                    .fontWeight(.semibold)
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(LevelSystem.levelTitle(for: profile.level))
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                            
                            // Action Button
                            friendActionButton
                        }
                        .padding(.top, 20)
                        
                        // Stats Grid
                        VStack(spacing: 12) {
                            HStack(spacing: 0) {
                                ProfileStatItem(value: "\(profile.totalWorkouts)", label: "Workouts")
                                
                                Divider()
                                    .frame(height: 40)
                                
                                ProfileStatItem(value: "\(profile.currentStreak)", label: "Day Streak")
                                
                                Divider()
                                    .frame(height: 40)
                                
                                ProfileStatItem(value: "\(profile.totalXP)", label: "Total XP")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        // Recent Activity
                        if profile.isPublic || isFriend {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Activity")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if userPosts.isEmpty {
                                    Text("No shared workouts yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 40)
                                } else {
                                    ForEach(userPosts.prefix(5)) { post in
                                        NavigationLink(destination: PostDetailView(post: post)) {
                                            UserActivityCard(post: post)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("Private Profile")
                                    .font(.headline)
                                
                                Text("Add as a friend to see their activity")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 40)
                        }
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
        .navigationBarHidden(true)
        .task {
            await loadProfile()
        }
    }
    
    @ViewBuilder
    private var friendActionButton: some View {
        if isFriend {
            Button(action: {
                Task {
                    isPerformingAction = true
                    try? await socialManager.removeFriend(userId)
                    isPerformingAction = false
                }
            }) {
                HStack(spacing: 8) {
                    if isPerformingAction {
                        ProgressView()
                            .tint(.red)
                    } else {
                        Image(systemName: "person.badge.minus")
                        Text("Remove Friend")
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
            .disabled(isPerformingAction)
        } else if friendshipStatus == .pending {
            Text("Request Pending")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(10)
        } else {
            Button(action: {
                Task {
                    isPerformingAction = true
                    try? await socialManager.sendFriendRequest(to: userId)
                    friendshipStatus = .pending
                    isPerformingAction = false
                }
            }) {
                HStack(spacing: 8) {
                    if isPerformingAction {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus")
                        Text("Add Friend")
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.utOrange)
                .cornerRadius(10)
            }
            .disabled(isPerformingAction)
        }
    }
    
    private func loadProfile() async {
        isLoading = true
        
        // Clear any previous data first
        userProfile = nil
        userPosts = []
        friendshipStatus = nil
        
        // Fetch fresh data from Firestore
        userProfile = await socialManager.fetchUserProfile(byId: userId)
        friendshipStatus = await socialManager.getFriendshipStatus(with: userId)
        userPosts = await feedManager.fetchUserPosts(userId: userId)
        
        isLoading = false
    }
}

// MARK: - Profile Stat Item

struct ProfileStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
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
            
            Text(timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: "test123")
    }
}
