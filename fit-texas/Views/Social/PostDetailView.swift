//
//  PostDetailView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI
import FirebaseAuth

struct PostDetailView: View {
    let post: FeedPost
    @StateObject private var feedManager = FeedManager.shared
    @StateObject private var socialManager = SocialManager.shared
    @ObservedObject private var historyManager = WorkoutHistoryManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var comments: [PostComment] = []
    @State private var newCommentText = ""
    @State private var isLoadingComments = true
    @State private var isSubmittingComment = false
    @State private var showDeleteConfirmation = false
    @State private var showImportConfirmation = false
    @State private var isSaved = false
    @FocusState private var isCommentFieldFocused: Bool
    
    private var isOwnPost: Bool {
        post.userId == Auth.auth().currentUser?.uid
    }
    
    private var isInActiveWorkout: Bool {
        historyManager.hasDraft
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: post.createdAt, relativeTo: Date())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Post Header - Profile Clickable
                    NavigationLink(destination: UserProfileView(userId: post.userId)) {
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
                                    Text(String(post.userDisplayName.prefix(1)).uppercased())
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(post.userDisplayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(timeAgo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    // Workout Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text(post.workoutName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Duration if available
                        if let duration = post.duration {
                            HStack(spacing: 6) {
                                Image(systemName: "timer")
                                    .foregroundColor(.utOrange)
                                Text(formatDuration(duration))
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                        }
                        
                        // Stats
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(post.exerciseCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Exercises")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack {
                                Text("\(post.totalSets)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Sets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack {
                                Text("\(Int(post.totalVolume))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("kg Volume")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            if isInActiveWorkout {
                                Button(action: addExercisesToWorkout) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add to Workout")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.utOrange)
                                    .cornerRadius(10)
                                }
                            } else {
                                Button(action: { showImportConfirmation = true }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Import Workout")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.utOrange)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.utOrange.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                            
                            Button(action: { isSaved.toggle() }) {
                                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                    .font(.title3)
                                    .foregroundColor(isSaved ? .utOrange : .secondary)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                        }
                        
                        // Exercise List - Clickable
                        if let summaries = post.exerciseSummaries, !summaries.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Exercises")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                ForEach(summaries, id: \.name) { exercise in
                                    ExerciseRowInPost(
                                        exercise: exercise,
                                        isInActiveWorkout: isInActiveWorkout,
                                        onAddToWorkout: { addSingleExercise(exercise.name) }
                                    )
                                }
                            }
                        }
                        
                        // Caption
                        if let caption = post.caption, !caption.isEmpty {
                            Text(caption)
                                .font(.body)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Like/Comment Section
                    HStack(spacing: 24) {
                        Button(action: {
                            Task {
                                try? await feedManager.toggleLike(for: post.id)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                                    .foregroundColor(post.isLikedByCurrentUser ? .red : .primary)
                                Text("\(post.likesCount) likes")
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                            Text("\(comments.count) comments")
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Divider()
                    
                    // Comments Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Comments")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 12)
                        
                        if isLoadingComments {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if comments.isEmpty {
                            Text("No comments yet. Be the first to comment!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(comments) { comment in
                                CommentRowView(comment: comment)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            
            // Comment Input
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    TextField("Add a comment...", text: $newCommentText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isCommentFieldFocused)
                    
                    Button(action: submitComment) {
                        if isSubmittingComment {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(newCommentText.isEmpty ? .secondary : .utOrange)
                        }
                    }
                    .disabled(newCommentText.isEmpty || isSubmittingComment)
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isOwnPost {
                    Menu {
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.utOrange)
                    }
                }
            }
        }
        .alert("Delete Post?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePost()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Import Workout?", isPresented: $showImportConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Import") {
                importWorkout()
            }
        } message: {
            Text("This will create a copy of this workout template in your workout history.")
        }
        .onAppear {
            loadComments()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) minutes"
    }
    
    private func loadComments() {
        Task {
            comments = await feedManager.fetchComments(for: post.id)
            isLoadingComments = false
        }
    }
    
    private func submitComment() {
        guard !newCommentText.isEmpty else { return }
        
        isSubmittingComment = true
        let text = newCommentText
        newCommentText = ""
        isCommentFieldFocused = false
        
        Task {
            do {
                try await feedManager.addComment(to: post.id, text: text)
                await MainActor.run {
                    loadComments()
                }
            } catch {
                print("Error adding comment: \(error)")
            }
            
            await MainActor.run {
                isSubmittingComment = false
            }
        }
    }
    
    private func deletePost() {
        Task {
            do {
                try await feedManager.deletePost(post.id)
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Error deleting post: \(error)")
            }
        }
    }
    
    private func importWorkout() {
        // Create exercises from summaries
        var exercises: [WorkoutExercise] = []
        
        if let summaries = post.exerciseSummaries {
            for summary in summaries {
                let sets = (0..<summary.setCount).map { _ in
                    WorkoutSet(reps: "", weight: "")
                }
                exercises.append(WorkoutExercise(name: summary.name, sets: sets))
            }
        }
        
        // Save as a template workout
        let workout = SavedWorkout(
            name: "\(post.workoutName) (Imported)",
            date: Date(),
            exercises: exercises
        )
        
        historyManager.saveWorkout(workout)
    }
    
    private func addExercisesToWorkout() {
        // Add all exercises to current draft
        if let summaries = post.exerciseSummaries {
            for summary in summaries {
                addSingleExercise(summary.name)
            }
        }
    }
    
    private func addSingleExercise(_ exerciseName: String) {
        // This would need to interface with the draft workout
        // For now, we'll use a notification or direct manager access
        NotificationCenter.default.post(
            name: NSNotification.Name("AddExerciseToWorkout"),
            object: nil,
            userInfo: ["exerciseName": exerciseName]
        )
    }
}

// MARK: - Exercise Row In Post

struct ExerciseRowInPost: View {
    let exercise: ExerciseSummary
    let isInActiveWorkout: Bool
    let onAddToWorkout: () -> Void
    
    @State private var matchedExercise: Exercise?
    
    var body: some View {
        HStack {
            if let matched = matchedExercise {
                NavigationLink(destination: ExerciseDetailView(exercise: matched)) {
                    exerciseContent
                }
            } else {
                exerciseContent
            }
            
            if isInActiveWorkout {
                Button(action: onAddToWorkout) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.utOrange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onAppear {
            findMatchingExercise()
        }
    }
    
    private var exerciseContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if matchedExercise != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("\(exercise.setCount) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let bestSet = exercise.bestSet {
                Text(bestSet)
                    .font(.subheadline)
                    .foregroundColor(.utOrange)
            }
        }
    }
    
    private func findMatchingExercise() {
        let loader = ExerciseLoader.shared
        
        if let match = loader.getExercise(byName: exercise.name) {
            matchedExercise = match
        } else {
            let results = loader.searchExercises(query: exercise.name)
            matchedExercise = results.first
        }
    }
}

// MARK: - Comment Row

struct CommentRowView: View {
    let comment: PostComment
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: comment.createdAt, relativeTo: Date())
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            NavigationLink(destination: UserProfileView(userId: comment.userId)) {
                Circle()
                    .fill(Color.utOrange.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(comment.userDisplayName.prefix(1)).uppercased())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.utOrange)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    NavigationLink(destination: UserProfileView(userId: comment.userId)) {
                        Text(comment.userDisplayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        PostDetailView(
            post: FeedPost(
                userId: "123",
                userDisplayName: "John Doe",
                workoutId: "456",
                workoutName: "Push Day",
                workoutDate: Date(),
                exerciseCount: 5,
                totalSets: 20,
                totalVolume: 5000,
                duration: 3600,
                caption: "Great workout today! 💪",
                likesCount: 12,
                commentsCount: 3,
                exerciseSummaries: [
                    ExerciseSummary(name: "Bench Press", setCount: 4, bestSet: "100kg x 8"),
                    ExerciseSummary(name: "Incline Dumbbell Press", setCount: 3, bestSet: "35kg x 10"),
                    ExerciseSummary(name: "Cable Flyes", setCount: 3, bestSet: "20kg x 12")
                ]
            )
        )
    }
}
