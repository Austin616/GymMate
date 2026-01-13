//
//  FriendsView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI

struct FriendsView: View {
    @StateObject private var socialManager = SocialManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTab = 0
    @State private var showUserSearch = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            CustomTabHeader(
                title: "Friends",
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
                trailingButton: AnyView(
                    Button(action: { showUserSearch = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.utOrange)
                            .font(.title3)
                    }
                ),
                isSubScreen: true
            )
            
            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Friends (\(socialManager.friends.count))").tag(0)
                Text("Requests (\(socialManager.pendingRequests.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            if selectedTab == 0 {
                FriendsListView()
            } else {
                FriendRequestsView()
            }
        }
        .navigationBarHidden(true)
        .background(
            NavigationLink(destination: UserSearchView(), isActive: $showUserSearch) {
                EmptyView()
            }
            .hidden()
        )
    }
}

// MARK: - Friends List View

struct FriendsListView: View {
    @StateObject private var socialManager = SocialManager.shared
    @State private var showRemoveAlert = false
    @State private var friendToRemove: UserProfile?
    
    var body: some View {
        if socialManager.friends.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                
                Image(systemName: "person.2.slash")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                
                Text("No Friends Yet")
                    .font(.headline)
                
                Text("Search for friends to add them!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        } else {
            List {
                ForEach(socialManager.friends) { friend in
                    NavigationLink(destination: UserProfileView(userId: friend.id)) {
                        FriendRow(profile: friend)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            friendToRemove = friend
                            showRemoveAlert = true
                        } label: {
                            Label("Remove", systemImage: "person.badge.minus")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .alert("Remove Friend", isPresented: $showRemoveAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    if let friend = friendToRemove {
                        Task {
                            try? await socialManager.removeFriend(friend.id)
                        }
                    }
                }
            } message: {
                if let friend = friendToRemove {
                    Text("Are you sure you want to remove \(friend.displayName) from your friends?")
                }
            }
        }
    }
}

// MARK: - Friend Requests View

struct FriendRequestsView: View {
    @StateObject private var socialManager = SocialManager.shared
    
    var body: some View {
        if socialManager.pendingRequests.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                
                Image(systemName: "envelope.badge")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                
                Text("No Pending Requests")
                    .font(.headline)
                
                Text("Friend requests will appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        } else {
            List {
                ForEach(socialManager.pendingRequests) { request in
                    FriendRequestRow(request: request)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.utOrange, Color.utOrange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(profile.displayName.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName)
                    .font(.headline)
                
                Text("@\(profile.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Level \(profile.level)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.utOrange)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("\(profile.currentStreak)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Friend Request Row

struct FriendRequestRow: View {
    let request: FriendRequest
    @StateObject private var socialManager = SocialManager.shared
    @State private var isAccepting = false
    @State private var isDeclining = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.utOrange, Color.utOrange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(request.fromUser.displayName.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(request.fromUser.displayName)
                    .font(.headline)
                
                Text("@\(request.fromUser.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    isAccepting = true
                    Task {
                        try? await socialManager.acceptFriendRequest(friendshipId: request.friendship.id)
                        isAccepting = false
                    }
                }) {
                    if isAccepting {
                        ProgressView()
                            .frame(width: 30, height: 30)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isAccepting || isDeclining)
                
                Button(action: {
                    isDeclining = true
                    Task {
                        try? await socialManager.declineFriendRequest(friendshipId: request.friendship.id)
                        isDeclining = false
                    }
                }) {
                    if isDeclining {
                        ProgressView()
                            .frame(width: 30, height: 30)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isAccepting || isDeclining)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        FriendsView()
    }
}
