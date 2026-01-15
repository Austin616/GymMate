//
//  UserSearchView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI

struct UserSearchView: View {
    @StateObject private var socialManager = SocialManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var searchQuery = ""
    @State private var allUsers: [UserProfile] = []
    @State private var isLoading = true
    
    private var filteredUsers: [UserProfile] {
        if searchQuery.isEmpty {
            return allUsers
        }
        let query = searchQuery.lowercased()
        return allUsers.filter {
            $0.username.lowercased().contains(query) ||
            $0.displayName.lowercased().contains(query)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search by username or name...", text: $searchQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            
            // Content
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading users...")
                    Spacer()
                }
            } else if filteredUsers.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "person.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No users found")
                        .font(.headline)
                    
                    if !searchQuery.isEmpty {
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredUsers) { user in
                        UserSearchRow(user: user)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Find Friends")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAllUsers()
        }
    }
    
    private func loadAllUsers() async {
        isLoading = true
        let users = await socialManager.getAllUsers()
        await MainActor.run {
            allUsers = users
            isLoading = false
        }
    }
}

// MARK: - User Search Row

struct UserSearchRow: View {
    let user: UserProfile
    @StateObject private var socialManager = SocialManager.shared
    @State private var isFollowing = false
    @State private var isFollowedBy = false // They follow us
    @State private var hasRequestedFollow = false
    @State private var isLoading = false
    
    private var areFriends: Bool {
        isFollowing && isFollowedBy
    }
    
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: UserProfileView(userId: user.id)) {
                HStack(spacing: 12) {
                    // Avatar
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
                            Text(String(user.displayName.prefix(1)).uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    // User Info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(user.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if !user.isPublic {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("@\(user.username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Text("Level \(user.level)")
                                .font(.caption2)
                                .foregroundColor(.utOrange)
                            
                            if user.currentStreak > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("\(user.currentStreak)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Action Button
            followButton
        }
        .padding(.vertical, 4)
        .task {
            await checkFollowStatus()
        }
    }
    
    @ViewBuilder
    private var followButton: some View {
        if areFriends {
            // Mutual follow - Friends
            Button(action: unfollowUser) {
                if isLoading {
                    ProgressView()
                        .frame(width: 20, height: 20)
                } else {
                    Text("Friends")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            .disabled(isLoading)
        } else if isFollowing {
            // We follow them but they don't follow us
            Button(action: unfollowUser) {
                if isLoading {
                    ProgressView()
                        .frame(width: 20, height: 20)
                } else {
                    Text("Following")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(8)
            .disabled(isLoading)
        } else if hasRequestedFollow {
            Button(action: cancelRequest) {
                if isLoading {
                    ProgressView()
                        .frame(width: 20, height: 20)
                } else {
                    Text("Requested")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(8)
            .disabled(isLoading)
        } else {
            Button(action: followUser) {
                if isLoading {
                    ProgressView()
                        .frame(width: 20, height: 20)
                } else {
                    Text(user.isPublic ? "Follow" : "Request")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.utOrange)
            .cornerRadius(8)
            .disabled(isLoading)
        }
    }
    
    private func checkFollowStatus() async {
        isFollowing = await socialManager.isFollowing(user.id)
        isFollowedBy = await socialManager.isFollowedBy(user.id)
        if !isFollowing {
            hasRequestedFollow = await socialManager.hasRequestedFollow(user.id)
        }
    }
    
    private func followUser() {
        isLoading = true
        
        Task {
            do {
                try await socialManager.followUser(user.id)
                await MainActor.run {
                    if user.isPublic {
                        isFollowing = true
                    } else {
                        hasRequestedFollow = true
                    }
                }
            } catch {
                print("Error following user: \(error)")
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func unfollowUser() {
        isLoading = true
        
        Task {
            do {
                try await socialManager.unfollowUser(user.id)
                await MainActor.run {
                    isFollowing = false
                }
            } catch {
                print("Error unfollowing user: \(error)")
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func cancelRequest() {
        isLoading = true
        
        Task {
            do {
                try await socialManager.cancelFollowRequest(to: user.id)
                await MainActor.run {
                    hasRequestedFollow = false
                }
            } catch {
                print("Error cancelling request: \(error)")
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserSearchView()
    }
}
