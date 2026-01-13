//
//  PostDetailView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI

struct PostDetailView: View {
    let post: FeedPost
    @StateObject private var feedManager = FeedManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var comments: [PostComment] = []
    @State private var newCommentText = ""
    @State private var isLoadingComments = true
    @State private var isSubmittingComment = false
    @FocusState private var isCommentFieldFocused: Bool
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: post.createdAt, relativeTo: Date())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            CustomTabHeader(
                title: "Post",
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Post Header
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
                            
                            Text(timeAgo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    // Workout Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text(post.workoutName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
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
                        
                        // Exercise List
                        if let summaries = post.exerciseSummaries, !summaries.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Exercises")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                ForEach(summaries, id: \.name) { exercise in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
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
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
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
                                CommentRow(comment: comment)
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
        .navigationBarHidden(true)
        .onAppear {
            loadComments()
        }
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
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: PostComment
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: comment.createdAt, relativeTo: Date())
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.utOrange.opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(comment.userDisplayName.prefix(1)).uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.utOrange)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userDisplayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
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
