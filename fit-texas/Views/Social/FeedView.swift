//
//  FeedView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI
import ContactsUI

struct FeedView: View {
    @StateObject private var feedManager = FeedManager.shared
    @StateObject private var socialManager = SocialManager.shared
    @State private var showFriends = false
    @State private var showInvite = false
    @State private var selectedTab = 0  // 0 = For You, 1 = Following
    
    var body: some View {
        VStack(spacing: 0) {
            // TikTok-style Header with centered tabs
            HStack {
                // Left button - Invite
                Button(action: { showInvite = true }) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.utOrange)
                        .font(.title3)
                }
                .frame(width: 44)
                
                Spacer()
                
                // Center - Tab switcher (TikTok style)
                HStack(spacing: 24) {
                    FeedTabButton(
                        title: "Following",
                        isSelected: selectedTab == 1,
                        action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 1 } }
                    )
                    
                    Text("|")
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    FeedTabButton(
                        title: "For You",
                        isSelected: selectedTab == 0,
                        action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 0 } }
                    )
                }
                
                Spacer()
                
                // Right button - Friends
                Button(action: { showFriends = true }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "person.2")
                            .foregroundColor(.utOrange)
                            .font(.title3)
                        
                        if socialManager.pendingRequests.count > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text("\(min(socialManager.pendingRequests.count, 9))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                .frame(width: 44)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Suggested Users Section (show at top of For You tab)
                    if selectedTab == 0 && !feedManager.suggestedUsers.isEmpty {
                        SuggestedUsersSection(users: feedManager.suggestedUsers)
                    }
                    
                    // Campus Posts
                    if filteredPosts.isEmpty && !feedManager.isLoading {
                        EmptyFeedStateView(
                            selectedTab: selectedTab,
                            onFindFriends: { showFriends = true },
                            onInvite: { showInvite = true }
                        )
                    } else {
                        ForEach(filteredPosts) { post in
                            NavigationLink(destination: PostDetailView(post: post)) {
                                FeedPostCard(post: post)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if feedManager.hasMorePosts && !feedManager.feedPosts.isEmpty {
                            ProgressView()
                                .padding()
                                .onAppear {
                                    Task {
                                        await feedManager.fetchFeed()
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .refreshable {
                await feedManager.fetchFeed(refresh: true)
                feedManager.loadSuggestedUsers()
            }
        }
        .navigationBarHidden(true)
        .background(
            Group {
                NavigationLink(destination: FriendsView(), isActive: $showFriends) {
                    EmptyView()
                }
            }
            .hidden()
        )
        .sheet(isPresented: $showInvite) {
            InviteFriendsSheet()
        }
    }
    
    private var filteredPosts: [FeedPost] {
        if selectedTab == 1 {
            // Following tab - show only friends' posts (not own posts)
            let friendIds = Set(socialManager.getFriendIds())
            return feedManager.feedPosts.filter { 
                friendIds.contains($0.userId)
            }
        }
        // For You tab - show all posts (own posts already excluded by FeedManager)
        return feedManager.feedPosts
    }
}

// MARK: - Feed Tab Button (TikTok style)

struct FeedTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                // Underline indicator
                Rectangle()
                    .fill(isSelected ? Color.utOrange : Color.clear)
                    .frame(width: 30, height: 2)
                    .cornerRadius(1)
            }
        }
    }
}

// MARK: - Suggested Users Section

struct SuggestedUsersSection: View {
    let users: [UserProfile]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Suggested for You")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                NavigationLink(destination: UserSearchView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.utOrange)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(users) { user in
                        SuggestedUserCard(user: user)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Suggested User Card

struct SuggestedUserCard: View {
    let user: UserProfile
    @StateObject private var socialManager = SocialManager.shared
    @State private var requestSent = false
    @State private var isLoading = false
    
    private var isFriend: Bool {
        socialManager.friends.contains { $0.id == user.id }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.utOrange, Color.utOrange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(user.displayName.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("Level \(user.level)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Follow Button
            if isFriend {
                Text("Following")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            } else if requestSent {
                Text("Requested")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            } else {
                Button(action: {
                    sendRequest()
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(width: 60, height: 24)
                    } else {
                        Text("Follow")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.utOrange)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .frame(width: 100)
        .padding(.vertical, 8)
    }
    
    private func sendRequest() {
        isLoading = true
        Task {
            do {
                try await socialManager.sendFriendRequest(to: user.id)
                await MainActor.run {
                    requestSent = true
                }
            } catch {
                print("Error sending request: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Empty Feed State View

struct EmptyFeedStateView: View {
    let selectedTab: Int
    let onFindFriends: () -> Void
    let onInvite: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if selectedTab == 1 {
                // Following tab empty state
                Image(systemName: "person.2.circle")
                    .font(.system(size: 70))
                    .foregroundColor(.utOrange.opacity(0.5))
                
                VStack(spacing: 8) {
                    Text("Follow accounts to see their workouts")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("When you follow people, their workout posts will show up here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Button(action: onFindFriends) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                        Text("Find People to Follow")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.utOrange)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            } else {
                // For You tab empty state
                Image(systemName: "newspaper")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.5))
                
                VStack(spacing: 8) {
                    Text("No Campus Posts Yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Be the first to share your workout with the campus!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 12) {
                    Button(action: onFindFriends) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text("Find People")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.utOrange)
                        .cornerRadius(12)
                    }
                    
                    Button(action: onInvite) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Invite Friends")
                        }
                        .font(.headline)
                        .foregroundColor(.utOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.utOrange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Invite Friends Sheet

struct InviteFriendsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    private let inviteMessage = "Join me on GymMate! Track your workouts, compete with friends, and level up your fitness journey. 💪🏋️"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.2.badge.gearshape")
                        .font(.system(size: 60))
                        .foregroundColor(.utOrange)
                    
                    Text("Invite Friends")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Share GymMate with your workout buddies and compete together!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 32)
                
                VStack(spacing: 16) {
                    // Share Options
                    InviteOptionButton(
                        icon: "message.fill",
                        title: "Send a Message",
                        subtitle: "Invite via text message",
                        color: .green
                    ) {
                        shareViaMessages()
                    }
                    
                    InviteOptionButton(
                        icon: "link",
                        title: "Copy Invite Link",
                        subtitle: "Share anywhere",
                        color: .blue
                    ) {
                        copyInviteLink()
                    }
                    
                    InviteOptionButton(
                        icon: "square.and.arrow.up",
                        title: "More Options",
                        subtitle: "Share via other apps",
                        color: .utOrange
                    ) {
                        showShareSheet = true
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.utOrange)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [inviteMessage])
        }
    }
    
    private func shareViaMessages() {
        // Open Messages with pre-filled text
        if let url = URL(string: "sms:&body=\(inviteMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func copyInviteLink() {
        UIPasteboard.general.string = inviteMessage
        // You could show a toast here
    }
}

// MARK: - Invite Option Button

struct InviteOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Share Sheet (UIKit Wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        FeedView()
    }
}
