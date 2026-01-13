//
//  ProfileSetupView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var socialManager = SocialManager.shared
    
    @State private var username = ""
    @State private var displayName = ""
    @State private var bio = ""
    @State private var isPublic = true
    
    @State private var currentStep = 0
    @State private var isCheckingUsername = false
    @State private var isUsernameAvailable = false
    @State private var usernameError: String?
    @State private var isSaving = false
    
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step <= currentStep ? Color.utOrange : Color(.systemGray5))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Step Content
                    switch currentStep {
                    case 0:
                        step1Content
                    case 1:
                        step2Content
                    case 2:
                        step3Content
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
            
            // Navigation Buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button(action: { currentStep -= 1 }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(.utOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.utOrange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Button(action: handleNext) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(currentStep == 2 ? "Complete" : "Next")
                            if currentStep < 2 {
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canProceed ? Color.utOrange : Color.utOrange.opacity(0.5))
                    .cornerRadius(12)
                }
                .disabled(!canProceed || isSaving)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Step 1: Username
    
    private var step1Content: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose a Username")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This is how friends will find you")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Username Input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("@")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    TextField("username", text: $username)
                        .font(.title2)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: username) { newValue in
                            // Clean username
                            let cleaned = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
                            if cleaned != newValue {
                                username = cleaned
                            }
                            
                            // Check availability
                            isUsernameAvailable = false
                            usernameError = nil
                            
                            if username.count >= 3 {
                                checkUsernameAvailability()
                            }
                        }
                    
                    if isCheckingUsername {
                        ProgressView()
                    } else if isUsernameAvailable {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if usernameError != nil {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if let error = usernameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if isUsernameAvailable {
                    Text("Username is available!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Text("3-20 characters, letters, numbers, and underscores only")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Step 2: Display Name & Bio
    
    private var step2Content: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Tell Us About Yourself")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Add some details to your profile")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Display Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                TextField("Your name", text: $displayName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            
            // Bio
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                    .lineLimit(3...5)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                Text("\(bio.count)/150")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear {
            if displayName.isEmpty {
                displayName = authManager.currentUser?.displayName ?? ""
            }
        }
    }
    
    // MARK: - Step 3: Privacy
    
    private var step3Content: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Privacy Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Control who can see your activity")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Privacy Toggle
            VStack(spacing: 16) {
                Button(action: { isPublic = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.utOrange)
                                Text("Public Profile")
                                    .fontWeight(.semibold)
                            }
                            
                            Text("Anyone can see your profile and shared workouts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isPublic ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isPublic ? .utOrange : .secondary)
                            .font(.title2)
                    }
                    .padding()
                    .background(isPublic ? Color.utOrange.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPublic ? Color.utOrange : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { isPublic = false }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                Text("Private Profile")
                                    .fontWeight(.semibold)
                            }
                            
                            Text("Only friends can see your profile and workouts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: !isPublic ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(!isPublic ? .utOrange : .secondary)
                            .font(.title2)
                    }
                    .padding()
                    .background(!isPublic ? Color.utOrange.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(!isPublic ? Color.utOrange : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Profile Summary")
                    .font(.headline)
                    .padding(.top, 8)
                
                HStack(spacing: 16) {
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
                            Text(String(displayName.prefix(1)).uppercased())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.headline)
                        
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: isPublic ? "globe" : "lock.fill")
                                .font(.caption2)
                            Text(isPublic ? "Public" : "Private")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return username.count >= 3 && isUsernameAvailable
        case 1:
            return !displayName.isEmpty
        case 2:
            return true
        default:
            return false
        }
    }
    
    private func handleNext() {
        if currentStep < 2 {
            currentStep += 1
        } else {
            saveProfile()
        }
    }
    
    private func checkUsernameAvailability() {
        isCheckingUsername = true
        usernameError = nil
        
        // Validate length
        if username.count < 3 {
            usernameError = "Username must be at least 3 characters"
            isCheckingUsername = false
            return
        }
        
        if username.count > 20 {
            usernameError = "Username must be 20 characters or less"
            isCheckingUsername = false
            return
        }
        
        Task {
            let available = await socialManager.checkUsernameAvailability(username)
            
            await MainActor.run {
                isCheckingUsername = false
                isUsernameAvailable = available
                if !available {
                    usernameError = "Username is already taken"
                }
            }
        }
    }
    
    private func saveProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isSaving = true
        
        let profile = UserProfile(
            id: userId,
            username: username.lowercased(),
            displayName: displayName,
            bio: bio,
            isPublic: isPublic
        )
        
        Task {
            do {
                // Reserve the username
                try await socialManager.reserveUsername(username, userId: userId)
                
                // Save the profile
                try await socialManager.createOrUpdateProfile(profile)
                
                await MainActor.run {
                    isSaving = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    usernameError = "Error saving profile. Please try again."
                }
            }
        }
    }
}

#Preview {
    ProfileSetupView(onComplete: {})
        .environmentObject(AuthManager())
}
