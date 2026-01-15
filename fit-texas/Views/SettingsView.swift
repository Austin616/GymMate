//
//  Settings.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var settingsManager = SettingsManager.shared
    @StateObject private var socialManager = SocialManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEditProfile = false
    @State private var isPublic: Bool = true

    var body: some View {
        List {
            // Profile Section
            Section(header: Text("Profile")) {
                if let profile = socialManager.currentUserProfile {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.utOrange)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(profile.displayName.prefix(1)).uppercased())
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.displayName)
                                .font(.headline)
                            Text("@\(profile.username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Edit") {
                            showEditProfile = true
                        }
                        .foregroundColor(.utOrange)
                    }
                    .padding(.vertical, 4)
                }
                
                Toggle(isOn: $isPublic) {
                    HStack {
                        Image(systemName: isPublic ? "globe" : "lock.fill")
                            .foregroundColor(.utOrange)
                        VStack(alignment: .leading) {
                            Text("Public Profile")
                            Text(isPublic ? "Anyone can see your activity" : "Only friends can see your activity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .tint(.utOrange)
                .onChange(of: isPublic) { newValue in
                    updateProfileVisibility(newValue)
                }
            }
            
            Section(header: Text("Appearance")) {
                Toggle(isOn: $settingsManager.isDarkModeEnabled) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.utOrange)
                        Text("Dark Mode")
                    }
                }
                .tint(.utOrange)
            }

            Section(header: Text("Units")) {
                Picker(selection: $settingsManager.weightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                } label: {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.utOrange)
                        Text("Weight Unit")
                    }
                }
            }
            
            Section(header: Text("Notifications")) {
                NavigationLink(destination: NotificationSettingsView()) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.utOrange)
                        Text("Notification Preferences")
                    }
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.utOrange)
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button(action: {
                    authManager.signOut()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .foregroundColor(.red)
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet()
        }
        .onAppear {
            if let profile = socialManager.currentUserProfile {
                isPublic = profile.isPublic
            }
        }
    }
    
    private func updateProfileVisibility(_ isPublic: Bool) {
        guard var profile = socialManager.currentUserProfile else { return }
        profile.isPublic = isPublic
        socialManager.updateUserProfile(profile)
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @StateObject private var socialManager = SocialManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display Name")) {
                    TextField("Display Name", text: $displayName)
                }
                
                Section(header: Text("Bio")) {
                    TextField("Tell us about yourself", text: $bio, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section(footer: Text("Username cannot be changed")) {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text("@\(socialManager.currentUserProfile?.username ?? "")")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(displayName.isEmpty || isSaving)
                }
            }
            .onAppear {
                if let profile = socialManager.currentUserProfile {
                    displayName = profile.displayName
                    bio = profile.bio
                }
            }
        }
    }
    
    private func saveProfile() {
        guard var profile = socialManager.currentUserProfile else { return }
        
        isSaving = true
        profile.displayName = displayName
        profile.bio = bio
        
        Task {
            do {
                try await socialManager.createOrUpdateProfile(profile)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error saving profile: \(error)")
            }
            await MainActor.run {
                isSaving = false
            }
        }
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @AppStorage("notifyAchievements") private var notifyAchievements = true
    @AppStorage("notifyFriendRequests") private var notifyFriendRequests = true
    @AppStorage("notifyChallenges") private var notifyChallenges = true
    @AppStorage("notifySocial") private var notifySocial = true
    
    var body: some View {
        List {
            Section(header: Text("Push Notifications")) {
                Toggle(isOn: $notifyAchievements) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.utOrange)
                        Text("Achievements")
                    }
                }
                .tint(.utOrange)
                
                Toggle(isOn: $notifyFriendRequests) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.utOrange)
                        Text("Friend Requests")
                    }
                }
                .tint(.utOrange)
                
                Toggle(isOn: $notifyChallenges) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.utOrange)
                        Text("Challenges")
                    }
                }
                .tint(.utOrange)
                
                Toggle(isOn: $notifySocial) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.utOrange)
                        Text("Likes & Comments")
                    }
                }
                .tint(.utOrange)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView().environmentObject(AuthManager())
    }
}
