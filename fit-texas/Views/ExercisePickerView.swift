//
//  ExercisePickerView.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI

enum ViewMode {
    case muscleGroups
    case allExercises
}

struct ExercisePickerView: View {
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedMuscleGroup: String?
    @State private var muscleGroups: [String] = []
    @State private var showFilters: Bool = false
    @State private var selectedEquipment: Set<String> = []
    @State private var selectedLevel: Set<String> = []
    @State private var selectedCategory: Set<String> = []
    @State private var viewMode: ViewMode = .muscleGroups
    @FocusState private var isSearchFocused: Bool

    var isSearching: Bool {
        !searchText.isEmpty
    }

    var filteredExercises: [Exercise] {
        var exercises = ExerciseLoader.shared.searchExercises(query: searchText)
        return applyFilters(to: exercises)
    }

    var allFilteredExercises: [Exercise] {
        var exercises = ExerciseLoader.shared.getAllExercises()
        return applyFilters(to: exercises)
    }

    var filteredExercisesForMuscle: [Exercise] {
        guard let muscleGroup = selectedMuscleGroup else { return [] }
        var exercises = ExerciseLoader.shared.getExercises(forMuscleGroup: muscleGroup)
        return applyFilters(to: exercises)
    }

    private func applyFilters(to exercises: [Exercise]) -> [Exercise] {
        var filtered = exercises

        // Apply equipment filter
        if !selectedEquipment.isEmpty {
            filtered = filtered.filter { exercise in
                guard let equipment = exercise.equipment else { return false }
                return selectedEquipment.contains(where: { $0.lowercased() == equipment.lowercased() })
            }
        }

        // Apply level filter
        if !selectedLevel.isEmpty {
            filtered = filtered.filter { exercise in
                guard let level = exercise.level else { return false }
                return selectedLevel.contains(where: { $0.lowercased() == level.lowercased() })
            }
        }

        // Apply category filter
        if !selectedCategory.isEmpty {
            filtered = filtered.filter { exercise in
                guard let category = exercise.category else { return false }
                return selectedCategory.contains(where: { $0.lowercased() == category.lowercased() })
            }
        }

        return filtered
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar

            // View Mode Toggle (only show when not searching and not in muscle detail)
            if !isSearching && selectedMuscleGroup == nil {
                viewModeToggle
                    .transition(.opacity)
            }

            // Filter Section
            if showFilters {
                filterSection
                    .transition(.opacity)
            }

            // Content
            Group {
                if isSearching {
                    // Show exercises directly when searching
                    exerciseList(filteredExercises)
                        .transition(.opacity)
                        .id("search")
                } else if selectedMuscleGroup != nil {
                    // Show exercises for selected muscle group
                    exerciseList(filteredExercisesForMuscle)
                        .transition(.opacity)
                        .id("muscle-detail")
                } else {
                    // Show muscle groups or all exercises based on toggle
                    if viewMode == .muscleGroups {
                        muscleGroupList
                            .transition(.opacity)
                            .id("muscle-groups")
                    } else {
                        exerciseList(allFilteredExercises)
                            .transition(.opacity)
                            .id("all-exercises")
                    }
                }
            }
        }
        .animation(.default, value: viewMode)
        .animation(.default, value: selectedMuscleGroup)
        .animation(.default, value: isSearching)
        .animation(.default, value: showFilters)
        .navigationTitle(selectedMuscleGroup ?? "Add Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(selectedMuscleGroup != nil && !isSearching)
        .toolbar {
            if selectedMuscleGroup != nil && !isSearching {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        withAnimation {
                            selectedMuscleGroup = nil
                            showFilters = false
                        }
                    }
                    .foregroundColor(.utOrange)
                }
            }
        }
        .onAppear {
            muscleGroups = ExerciseLoader.shared.getMuscleGroups()
        }
    }

    // MARK: - View Mode Toggle
    private var viewModeToggle: some View {
        HStack(spacing: 0) {
            Button(action: {
                viewMode = .muscleGroups
            }) {
                Text("Muscle Groups")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(viewMode == .muscleGroups ? Color.utOrange : Color.clear)
                    .foregroundColor(viewMode == .muscleGroups ? .white : .primary)
            }
            .buttonStyle(.plain)

            Button(action: {
                viewMode = .allExercises
            }) {
                Text("All Exercises")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(viewMode == .allExercises ? Color.utOrange : Color.clear)
                    .foregroundColor(viewMode == .allExercises ? .white : .primary)
            }
            .buttonStyle(.plain)
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search exercises", text: $searchText)
                        .focused($isSearchFocused)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                Button(action: {
                    withAnimation {
                        showFilters.toggle()
                    }
                }) {
                    Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(hasActiveFilters ? .utOrange : .secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 12) {
            Divider()

            // Equipment Filter
            filterRow(
                title: "Equipment",
                options: ["Barbell", "Dumbbell", "Machine", "Cable", "Body Only", "Kettlebells", "Bands"],
                selection: $selectedEquipment
            )

            // Level Filter
            filterRow(
                title: "Level",
                options: ["Beginner", "Intermediate", "Expert"],
                selection: $selectedLevel
            )

            // Category Filter
            filterRow(
                title: "Category",
                options: ["Strength", "Stretching", "Cardio"],
                selection: $selectedCategory
            )

            // Clear Filters Button
            if hasActiveFilters {
                Button(action: clearFilters) {
                    Text("Clear All Filters")
                        .font(.subheadline)
                        .foregroundColor(.utOrange)
                }
                .padding(.top, 4)
            }

            Divider()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }

    private func filterRow(title: String, options: [String], selection: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            if selection.wrappedValue.contains(option) {
                                selection.wrappedValue.remove(option)
                            } else {
                                selection.wrappedValue.insert(option)
                            }
                        }) {
                            Text(option)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selection.wrappedValue.contains(option)
                                        ? Color.utOrange
                                        : Color(.systemGray6)
                                )
                                .foregroundColor(
                                    selection.wrappedValue.contains(option)
                                        ? .white
                                        : .primary
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    private var hasActiveFilters: Bool {
        !selectedEquipment.isEmpty || !selectedLevel.isEmpty || !selectedCategory.isEmpty
    }

    private func clearFilters() {
        selectedEquipment.removeAll()
        selectedLevel.removeAll()
        selectedCategory.removeAll()
    }

    // MARK: - Muscle Group List
    private var muscleGroupList: some View {
        List {
            ForEach(muscleGroups, id: \.self) { muscleGroup in
                Button(action: {
                    selectedMuscleGroup = muscleGroup
                    showFilters = false
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.utOrange.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: muscleIcon(for: muscleGroup))
                                .font(.title3)
                                .foregroundColor(.utOrange)
                        }

                        Text(muscleGroup)
                            .foregroundColor(.primary)
                            .font(.headline)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Exercise List
    private func exerciseList(_ exercises: [Exercise]) -> some View {
        List {
            ForEach(exercises) { exercise in
                Button(action: {
                    onSelect(exercise.name)
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.utOrange.opacity(0.15))
                                .frame(width: 30, height: 30)
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption)
                                .foregroundColor(.utOrange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .foregroundColor(.primary)
                                .font(.body)

                            if let equipment = exercise.equipment {
                                Text(equipment.capitalized)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }

                        Spacer()

                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.utOrange)
                            .font(.title3)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Helper Functions
    private func muscleIcon(for muscleGroup: String) -> String {
        switch muscleGroup.lowercased() {
        case "chest": return "heart.fill"
        case "back": return "figure.walk"
        case "shoulders": return "arrow.up.circle.fill"
        case "biceps": return "hand.raised.fill"
        case "triceps": return "hand.raised.fill"
        case "forearms": return "hand.raised.fill"
        case "abdominals", "abs": return "square.grid.3x3.fill"
        case "quadriceps", "quads": return "figure.walk"
        case "hamstrings": return "figure.walk"
        case "calves": return "figure.walk"
        case "glutes": return "figure.walk"
        case "lower back": return "arrow.down.circle.fill"
        case "middle back": return "arrow.left.and.right.circle.fill"
        case "lats": return "arrow.left.and.right.circle.fill"
        case "traps": return "arrow.up.circle.fill"
        case "neck": return "circle.fill"
        default: return "figure.strengthtraining.traditional"
        }
    }
}
