//
//  FeedPostCard.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI

struct FeedPostCard: View {
    let post: FeedPost
    @StateObject private var feedManager = FeedManager.shared
    @State private var isLikeAnimating = false
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: post.createdAt, relativeTo: Date())
    }
    
    private var durationString: String? {
        guard let duration = post.duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - Profile is clickable
            HStack(spacing: 12) {
                // Avatar - Clickable to profile
                NavigationLink(destination: UserProfileView(userId: post.userId)) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.utOrange, Color.utOrange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(post.userDisplayName.prefix(1)).uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                
                // Name - Clickable to profile
                NavigationLink(destination: UserProfileView(userId: post.userId)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.userDisplayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: {}) {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
            .padding()
            
            // Workout Info
            VStack(alignment: .leading, spacing: 12) {
                Text(post.workoutName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Stats Row
                HStack(spacing: 12) {
                    StatBadge(icon: "figure.strengthtraining.traditional", value: "\(post.exerciseCount)", label: "exercises")
                    StatBadge(icon: "number.circle.fill", value: "\(post.totalSets)", label: "sets")
                    StatBadge(icon: "scalemass.fill", value: "\(Int(post.totalVolume))", label: "kg")
                }
                
                // Duration Badge (prominent)
                if let duration = durationString {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.subheadline)
                            .foregroundColor(.utOrange)
                        Text("Workout Duration: \(duration)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.utOrange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Exercise Summaries - Clickable to exercise detail
                if let summaries = post.exerciseSummaries, !summaries.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(summaries.prefix(3), id: \.name) { exercise in
                            ExerciseRowLink(exercise: exercise)
                        }
                        
                        if summaries.count > 3 {
                            Text("+ \(summaries.count - 3) more exercises")
                                .font(.caption)
                                .foregroundColor(.utOrange)
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Caption
                if let caption = post.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            Divider()
            
            // Footer - Like & Comment
            HStack(spacing: 24) {
                // Like Button
                Button(action: {
                    Task {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isLikeAnimating = true
                        }
                        try? await feedManager.toggleLike(for: post.id)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isLikeAnimating = false
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .font(.body)
                            .foregroundColor(post.isLikedByCurrentUser ? .red : .secondary)
                            .scaleEffect(isLikeAnimating ? 1.3 : 1.0)
                        
                        Text("\(post.likesCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                // Comment Button
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("\(post.commentsCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Share Button
                Button(action: {
                    // Share functionality
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Exercise Row Link (Clickable)

struct ExerciseRowLink: View {
    let exercise: ExerciseSummary
    @State private var matchedExercise: Exercise?
    
    var body: some View {
        Group {
            if let matched = matchedExercise {
                NavigationLink(destination: ExerciseDetailView(exercise: matched)) {
                    exerciseRowContent
                }
            } else {
                exerciseRowContent
            }
        }
        .onAppear {
            findMatchingExercise()
        }
    }
    
    private var exerciseRowContent: some View {
        HStack {
            Text(exercise.name)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            if matchedExercise != nil {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let bestSet = exercise.bestSet {
                Text(bestSet)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(exercise.setCount) sets")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func findMatchingExercise() {
        let loader = ExerciseLoader.shared
        
        // Try to find exact match first
        if let match = loader.getExercise(byName: exercise.name) {
            matchedExercise = match
        } else {
            // Try searching for partial match
            let results = loader.searchExercises(query: exercise.name)
            matchedExercise = results.first
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.utOrange)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if !label.isEmpty {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FeedPostCard(
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
        .padding()
    }
}
