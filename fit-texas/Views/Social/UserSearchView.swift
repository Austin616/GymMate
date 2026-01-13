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
    @State private var searchResults: [UserProfile] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            CustomTabHeader(
                title: "Find Friends",
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
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search by username...", text: $searchQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                        searchResults = []
                        hasSearched = false
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
            if isSearching {
                VStack {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                }
            } else if hasSearched && searchResults.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "person.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No users found")
                        .font(.headline)
                    
                    Text("Try a different username")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            } else if !searchResults.isEmpty {
                List {
                    ForEach(searchResults) { user in
                        UserSearchRow(user: user)
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Search for Friends")
                        .font(.headline)
                    
                    Text("Enter a username to find and add friends")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        hasSearched = true
        
        Task {
            let results = await socialManager.searchUsers(query: searchQuery)
            
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        }
    }
}

// MARK: - User Search Row

struct UserSearchRow: View {
    let user: UserProfile
    @StateObject private var socialManager = SocialManager.shared
    @State private var friendshipStatus: FriendshipStatus?
    @State private var isLoading = false
    @State private var requestSent = false
    
    private var isFriend: Bool {
        socialManager.friends.contains { $0.id == user.id }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: UserProfileView(userId: user.id)) {
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
                            Text(String(user.displayName.prefix(1)).uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
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
            if isFriend {
                Text("Friends")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            } else if requestSent || friendshipStatus == .pending {
                Text("Pending")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            } else {
                Button(action: sendRequest) {
                    if isLoading {
                        ProgressView()
                            .frame(width: 20, height: 20)
                    } else {
                        Text("Add")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.utOrange)
                .cornerRadius(8)
                .disabled(isLoading)
            }
        }
        .padding(.vertical, 4)
        .task {
            friendshipStatus = await socialManager.getFriendshipStatus(with: user.id)
        }
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
                print("Error sending friend request: \(error)")
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
