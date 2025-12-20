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
            CustomTabHeader(
                title: "Add Exercise",
                leadingButton: AnyView(
                    Button(action: {
                        dismiss()
                    }) {
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
            searchBar

            // View Mode Toggle (only show when not searching)
            if !isSearching {
                viewModeToggle
                    .transition(.opacity)
            }

            // Filter Section
            if showFilters {
                filterSection
                    .transition(.opacity)
            }

            // Content
            if isSearching {
                // Show exercises directly when searching
                exerciseList(filteredExercises)
            } else {
                // Show muscle groups or all exercises based on toggle
                if viewMode == .muscleGroups {
                    muscleGroupList
                } else {
                    exerciseList(allFilteredExercises)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewMode) { _ in
            if showFilters {
                showFilters = false
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewMode = .muscleGroups
                }
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewMode = .allExercises
                }
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
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(hasActiveFilters ? .utOrange : .secondary)

                        if hasActiveFilters {
                            Text("\(activeFilterCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
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

    private var activeFilterCount: Int {
        selectedEquipment.count + selectedLevel.count + selectedCategory.count
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
                NavigationLink(destination: muscleExerciseListView(for: muscleGroup)) {
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
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(.plain)
    }

    private func muscleExerciseListView(for muscleGroup: String) -> some View {
        MuscleExerciseListView(muscleGroup: muscleGroup, onSelect: { exerciseName in
            onSelect(exerciseName)
        })
    }

    // MARK: - Exercise List
    private func exerciseList(_ exercises: [Exercise]) -> some View {
        Group {
            if exercises.isEmpty {
                emptyStateView
            } else if exercises.count < 3 && hasActiveFilters {
                VStack(spacing: 0) {
                    limitedResultsView(count: exercises.count)
                    List {
                        ForEach(exercises) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                List {
                    ForEach(exercises) { exercise in
                        exerciseRow(exercise)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
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

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Exercises Found")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Try adjusting your filters to see more results")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if hasActiveFilters {
                Button(action: clearFilters) {
                    Text("Clear All Filters")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.utOrange)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func limitedResultsView(count: Int) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.utOrange)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Only \(count) \(count == 1 ? "exercise" : "exercises") found")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Clear some filters to see more options")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: clearFilters) {
                    Text("Clear")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.utOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.utOrange.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(Color.utOrange.opacity(0.08))
        }
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

// MARK: - Muscle Exercise List View
struct MuscleExerciseListView: View {
    let muscleGroup: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var showFilters: Bool = false
    @State private var selectedEquipment: Set<String> = []
    @State private var selectedLevel: Set<String> = []
    @State private var selectedCategory: Set<String> = []
    @FocusState private var isSearchFocused: Bool

    private var allExercises: [Exercise] {
        ExerciseLoader.shared.getExercises(forMuscleGroup: muscleGroup)
    }

    private var filteredExercises: [Exercise] {
        var exercises = allExercises

        // Apply search
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.equipment?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Apply filters
        return applyFilters(to: exercises)
    }

    private func applyFilters(to exercises: [Exercise]) -> [Exercise] {
        var filtered = exercises

        if !selectedEquipment.isEmpty {
            filtered = filtered.filter { exercise in
                guard let equipment = exercise.equipment else { return false }
                return selectedEquipment.contains(where: { $0.lowercased() == equipment.lowercased() })
            }
        }

        if !selectedLevel.isEmpty {
            filtered = filtered.filter { exercise in
                guard let level = exercise.level else { return false }
                return selectedLevel.contains(where: { $0.lowercased() == level.lowercased() })
            }
        }

        if !selectedCategory.isEmpty {
            filtered = filtered.filter { exercise in
                guard let category = exercise.category else { return false }
                return selectedCategory.contains(where: { $0.lowercased() == category.lowercased() })
            }
        }

        return filtered
    }

    private var hasActiveFilters: Bool {
        !selectedEquipment.isEmpty || !selectedLevel.isEmpty || !selectedCategory.isEmpty
    }

    private var activeFilterCount: Int {
        selectedEquipment.count + selectedLevel.count + selectedCategory.count
    }

    private func clearFilters() {
        selectedEquipment.removeAll()
        selectedLevel.removeAll()
        selectedCategory.removeAll()
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomTabHeader(
                title: muscleGroup,
                leadingButton: AnyView(
                    Button(action: {
                        dismiss()
                    }) {
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
            ExerciseSearchBar(
                searchText: $searchText,
                showFilters: $showFilters,
                hasActiveFilters: hasActiveFilters,
                activeFilterCount: activeFilterCount,
                isSearchFocused: $isSearchFocused,
                placeholder: "Search \(muscleGroup) exercises"
            )

            // Filter Section
            if showFilters {
                ExerciseFilterSection(
                    selectedEquipment: $selectedEquipment,
                    selectedLevel: $selectedLevel,
                    selectedCategory: $selectedCategory,
                    hasActiveFilters: hasActiveFilters,
                    clearFilters: clearFilters
                )
                .transition(.opacity)
            }

            // Exercise List
            ExerciseListContent(
                exercises: filteredExercises,
                hasActiveFilters: hasActiveFilters,
                clearFilters: clearFilters,
                onSelect: { exerciseName in
                    onSelect(exerciseName)
                }
            )
        }
        .animation(.default, value: showFilters)
        .navigationBarHidden(true)
    }
}

// MARK: - Reusable Components

struct ExerciseSearchBar: View {
    @Binding var searchText: String
    @Binding var showFilters: Bool
    var hasActiveFilters: Bool
    var activeFilterCount: Int
    @FocusState.Binding var isSearchFocused: Bool
    var placeholder: String = "Search exercises"

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField(placeholder, text: $searchText)
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
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(hasActiveFilters ? .utOrange : .secondary)

                        if hasActiveFilters {
                            Text("\(activeFilterCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
}

struct ExerciseFilterSection: View {
    @Binding var selectedEquipment: Set<String>
    @Binding var selectedLevel: Set<String>
    @Binding var selectedCategory: Set<String>
    var hasActiveFilters: Bool
    var clearFilters: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Divider()

            FilterRow(
                title: "Equipment",
                options: ["Barbell", "Dumbbell", "Machine", "Cable", "Body Only", "Kettlebells", "Bands"],
                selection: $selectedEquipment
            )

            FilterRow(
                title: "Level",
                options: ["Beginner", "Intermediate", "Expert"],
                selection: $selectedLevel
            )

            FilterRow(
                title: "Category",
                options: ["Strength", "Stretching", "Cardio"],
                selection: $selectedCategory
            )

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
}

struct FilterRow: View {
    let title: String
    let options: [String]
    @Binding var selection: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            if selection.contains(option) {
                                selection.remove(option)
                            } else {
                                selection.insert(option)
                            }
                        }) {
                            Text(option)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selection.contains(option)
                                    ? Color.utOrange
                                    : Color(.systemGray6)
                                )
                                .foregroundColor(
                                    selection.contains(option)
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
}

struct ExerciseListContent: View {
    let exercises: [Exercise]
    let hasActiveFilters: Bool
    let clearFilters: () -> Void
    let onSelect: (String) -> Void

    var body: some View {
        Group {
            if exercises.isEmpty {
                EmptyExerciseState(
                    hasActiveFilters: hasActiveFilters,
                    clearFilters: clearFilters
                )
            } else if exercises.count < 3 && hasActiveFilters {
                VStack(spacing: 0) {
                    LimitedResultsBanner(
                        count: exercises.count,
                        clearFilters: clearFilters
                    )
                    List {
                        ForEach(exercises) { exercise in
                            ExerciseRowButton(exercise: exercise, onSelect: onSelect)
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                List {
                    ForEach(exercises) { exercise in
                        ExerciseRowButton(exercise: exercise, onSelect: onSelect)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct ExerciseRowButton: View {
    let exercise: Exercise
    let onSelect: (String) -> Void
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: 12) {
            // Main row - tappable to show detail
            Button(action: {
                showDetail = true
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
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Quick add button
            Button(action: {
                onSelect(exercise.name)
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.utOrange)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showDetail) {
            ExerciseDetailView(
                exercise: exercise,
                onAdd: {
                    onSelect(exercise.name)
                }
            )
        }
    }
}

struct EmptyExerciseState: View {
    let hasActiveFilters: Bool
    let clearFilters: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Exercises Found")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Try adjusting your filters to see more results")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if hasActiveFilters {
                Button(action: clearFilters) {
                    Text("Clear All Filters")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.utOrange)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LimitedResultsBanner: View {
    let count: Int
    let clearFilters: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.utOrange)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Only \(count) \(count == 1 ? "exercise" : "exercises") found")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Clear some filters to see more options")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: clearFilters) {
                    Text("Clear")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.utOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.utOrange.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(Color.utOrange.opacity(0.08))
        }
    }
}
