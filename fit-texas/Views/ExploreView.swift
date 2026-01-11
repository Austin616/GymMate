//
//  ExploreView.swift
//  fit-texas
//
//  Created by Claude Code on 12/18/25.
//

import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String?
    @State private var showingExerciseDetail: Exercise?

    private let muscleGroups = ExerciseLoader.shared.getMuscleGroups()

    private var searchResults: [Exercise] {
        if searchText.isEmpty {
            return []
        }
        return ExerciseLoader.shared.searchExercises(query: searchText)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    CustomTabHeader(title: "Explore Exercises")

                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(.plain)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    if searchText.isEmpty {
                        // Featured Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Browse by Muscle Group")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            // Muscle Group Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(muscleGroups, id: \.self) { muscleGroup in
                                    NavigationLink(destination: MuscleGroupExercisesView(muscleGroup: muscleGroup)) {
                                        MuscleGroupCard(muscleGroup: muscleGroup)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Popular Exercises
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Popular Exercises")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(ExerciseLoader.shared.getAllExercises().prefix(10)) { exercise in
                                        PopularExerciseCard(exercise: exercise)
                                            .onTapGesture {
                                                showingExerciseDetail = exercise
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)

                    } else {
                        // Search Results
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(searchResults.count) results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            ForEach(searchResults) { exercise in
                                Button(action: {
                                    showingExerciseDetail = exercise
                                }) {
                                    SearchResultRow(exercise: exercise, onAdd: {})
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $showingExerciseDetail) { exercise in
            ExerciseDetailView(exercise: exercise, onAdd: {})
        }
    }
}

// MARK: - Muscle Group Card

struct MuscleGroupCard: View {
    let muscleGroup: String

    private var icon: String {
        switch muscleGroup.lowercased() {
        case "chest": return "heart.fill"
        case "back": return "arrow.left.arrow.right"
        case "shoulders": return "figure.arms.open"
        case "legs": return "figure.walk"
        case "arms": return "figure.strengthtraining.traditional"
        case "core", "abdominals": return "square.grid.3x3"
        case "glutes": return "figure.run"
        case "calves": return "figure.walk"
        case "biceps": return "dumbbell.fill"
        case "triceps": return "figure.gymnastics"
        case "forearms": return "hand.raised.fill"
        default: return "figure.strengthtraining.traditional"
        }
    }

    private var gradient: [Color] {
        switch muscleGroup.lowercased() {
        case "chest": return [Color.red, Color.pink]
        case "back": return [Color.blue, Color.cyan]
        case "shoulders": return [Color.orange, Color.yellow]
        case "legs": return [Color.green, Color.mint]
        case "arms", "biceps", "triceps": return [Color.purple, Color.indigo]
        case "core", "abdominals": return [Color.orange, Color.red]
        default: return [Color.utOrange, Color.orange]
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.15)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(height: 100)
            .cornerRadius(16)

            Text(muscleGroup.capitalized)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Popular Exercise Card

struct PopularExerciseCard: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.utOrange.opacity(0.15))
                    .frame(height: 120)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundColor(.utOrange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let equipment = exercise.equipment {
                    Text(equipment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 160)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let exercise: Exercise
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.utOrange.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3)
                    .foregroundColor(.utOrange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    if let equipment = exercise.equipment {
                        Label(equipment, systemImage: "dumbbell.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let level = exercise.level {
                        Label(level, systemImage: "chart.bar.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.utOrange)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Muscle Group Exercises View

struct MuscleGroupExercisesView: View {
    let muscleGroup: String
    @State private var showingExerciseDetail: Exercise?

    private var exercises: [Exercise] {
        ExerciseLoader.shared.getAllExercises().filter { exercise in
            exercise.primaryMuscles?.contains { $0.lowercased() == muscleGroup.lowercased() } ?? false
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Image
                ZStack {
                    LinearGradient(
                        colors: [Color.utOrange.opacity(0.3), Color.utOrange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 150)

                    VStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 50))
                            .foregroundColor(.utOrange)

                        Text(muscleGroup.capitalized)
                            .font(.title.bold())
                            .foregroundColor(.primary)

                        Text("\(exercises.count) exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Exercises List
                ForEach(exercises) { exercise in
                    Button(action: {
                        showingExerciseDetail = exercise
                    }) {
                        SearchResultRow(exercise: exercise, onAdd: {})
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 50)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $showingExerciseDetail) { exercise in
            ExerciseDetailView(exercise: exercise, onAdd: {})
        }
    }
}

#Preview {
    ExploreView()
}
