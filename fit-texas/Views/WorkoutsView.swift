//
//  WorkoutsView.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import SwiftUI

struct WorkoutsView: View {
    @StateObject private var historyManager = WorkoutHistoryManager()
    @State private var selectedDate = Date()
    @State private var currentWeekStart = Date().startOfWeek
    @State private var showNewWorkout = false
    @State private var showPastWorkouts = false
    @State private var selectedWorkoutTemplate: SavedWorkout?

    private var workoutsForSelectedDay: [SavedWorkout] {
        historyManager.savedWorkouts.filter { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CustomTabHeader(title: "Workouts")

                // Week Calendar
                WeekCalendarView(
                    selectedDate: $selectedDate,
                    currentWeekStart: $currentWeekStart,
                    workouts: historyManager.savedWorkouts
                )

                Divider()
                    .padding(.top, 12)

                // Selected Day Content
                if workoutsForSelectedDay.isEmpty {
                    EmptyDayView(
                        selectedDate: selectedDate,
                        onStartNew: {
                            selectedWorkoutTemplate = nil
                            showNewWorkout = true
                        },
                        onPickFromPast: {
                            showPastWorkouts = true
                        }
                    )
                } else {
                    DayWorkoutsView(
                        workouts: workoutsForSelectedDay,
                        onStartNew: {
                            selectedWorkoutTemplate = nil
                            showNewWorkout = true
                        }
                    )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNewWorkout) {
                ActiveWorkoutView(
                    historyManager: historyManager,
                    templateWorkout: selectedWorkoutTemplate,
                    onSave: {
                        showNewWorkout = false
                        selectedWorkoutTemplate = nil
                    },
                    onCancel: {
                        showNewWorkout = false
                        selectedWorkoutTemplate = nil
                    }
                )
            }
            .sheet(isPresented: $showPastWorkouts) {
                PastWorkoutsPickerView(
                    historyManager: historyManager,
                    onSelect: { workout in
                        selectedWorkoutTemplate = workout
                        showPastWorkouts = false
                        showNewWorkout = true
                    },
                    onDismiss: {
                        showPastWorkouts = false
                    }
                )
            }
        }
    }
}

// MARK: - Week Calendar View

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var currentWeekStart: Date
    let workouts: [SavedWorkout]

    @State private var slideDirection: Edge = .trailing

    private var weekDays: [Date] {
        (0..<7).compactMap { day in
            Calendar.current.date(byAdding: .day, value: day, to: currentWeekStart)
        }
    }

    private func hasWorkout(on date: Date) -> Bool {
        workouts.contains { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: date)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month/Year + Navigation
            HStack {
                Button(action: previousWeek) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.utOrange)
                        .font(.body)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text(monthYearString)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: nextWeek) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.utOrange)
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 20)

            // Week Days
            HStack(spacing: 4) {
                ForEach(weekDays, id: \.self) { date in
                    WeekDayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        hasWorkout: hasWorkout(on: date),
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = date
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
            .transition(.asymmetric(
                insertion: .move(edge: slideDirection),
                removal: .move(edge: slideDirection == .leading ? .trailing : .leading)
            ))
            .id(currentWeekStart)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private func previousWeek() {
        guard let newWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart),
              let newSelectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) else { return }

        slideDirection = .leading
        withAnimation(.linear(duration: 0.25)) {
            currentWeekStart = newWeek
            selectedDate = newSelectedDate
        }
    }

    private func nextWeek() {
        guard let newWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart),
              let newSelectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) else { return }

        slideDirection = .trailing
        withAnimation(.linear(duration: 0.25)) {
            currentWeekStart = newWeek
            selectedDate = newSelectedDate
        }
    }
}

struct WeekDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasWorkout: Bool
    let onTap: () -> Void

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Day of week label
                Text(dayOfWeek)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .utOrange : .secondary)
                    .textCase(.uppercase)

                // Date number circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.utOrange : Color(.systemGray6))
                        .frame(width: 44, height: 44)

                    Text(dayNumber)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                }

                // Workout indicator dot
                Circle()
                    .fill(hasWorkout && !isSelected ? Color.utOrange : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty Day View

struct EmptyDayView: View {
    let selectedDate: Date
    let onStartNew: () -> Void
    let onPickFromPast: () -> Void

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.utOrange.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Workout")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(isToday ? "No workout logged for today" : "No workout on \(dateString)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(action: onStartNew) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Start New Workout")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.utOrange)
                    .cornerRadius(12)
                }

                Button(action: onPickFromPast) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                        Text("Use Favorite Workout")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.utOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.utOrange, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Day Workouts View

struct DayWorkoutsView: View {
    let workouts: [SavedWorkout]
    let onStartNew: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(workouts) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            WorkoutDayCard(workout: workout)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }

            // Floating Action Button
            Button(action: onStartNew) {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Color.utOrange)
                            .shadow(color: Color.utOrange.opacity(0.4), radius: 12, x: 0, y: 4)
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
    }
}

struct WorkoutDayCard: View {
    let workout: SavedWorkout

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(timeString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.utOrange.opacity(0.15), Color.utOrange.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Stats
            HStack(spacing: 0) {
                StatItem(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(workout.exercises.count)",
                    label: "exercises"
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    icon: "number.circle.fill",
                    value: "\(workout.totalSets)",
                    label: "sets"
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    icon: "scalemass.fill",
                    value: "\(Int(workout.totalVolume))",
                    label: "kg"
                )
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.utOrange)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Workout Detail View

struct WorkoutDetailView: View {
    let workout: SavedWorkout
    @StateObject private var historyManager = WorkoutHistoryManager()
    @Environment(\.presentationMode) var presentationMode

    @State private var workoutName: String
    @State private var exercises: [WorkoutExercise]
    @State private var showDeleteConfirmation = false
    @State private var hasChanges = false

    init(workout: SavedWorkout) {
        self.workout = workout
        _workoutName = State(initialValue: workout.name)
        _exercises = State(initialValue: workout.exercises)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }

    var totalVolume: Double {
        exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { setTotal, set in
                let weight = Double(set.weight) ?? 0.0
                let reps = Double(set.reps) ?? 0.0
                return setTotal + (weight * reps)
            }
        }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack(alignment: .center) {
                Button(action: {
                    if hasChanges {
                        saveChanges()
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("Back")
                    }
                    .foregroundColor(.utOrange)
                }

                Spacer()

                Button(action: {
                    historyManager.toggleFavorite(workout)
                }) {
                    Image(systemName: workout.isFavorite ? "star.fill" : "star")
                        .foregroundColor(.utOrange)
                        .font(.title2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))

            // Editable Workout Title
            VStack(alignment: .leading, spacing: 4) {
                TextField("Workout Name", text: $workoutName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .onChange(of: workoutName) { _ in hasChanges = true }

                Text(dateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))

            ScrollView {
                VStack(spacing: 16) {
                    // Stats
                    HStack(spacing: 12) {
                        StatCardSmall(title: "Exercises", value: "\(exercises.count)", icon: "figure.strengthtraining.traditional")
                        StatCardSmall(title: "Sets", value: "\(totalSets)", icon: "number.circle")
                        StatCardSmall(title: "Volume", value: "\(Int(totalVolume)) kg", icon: "scalemass")
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Exercises
                    VStack(spacing: 12) {
                        ForEach(Array(exercises.enumerated()), id: \.element.id) { idx, exercise in
                            ExerciseCard(
                                exercise: bindingForExercise(at: idx),
                                exerciseIndex: idx,
                                onDelete: { deleteExercise(at: idx) },
                                disabled: false
                            )
                            .onChange(of: exercises[idx]) { _ in hasChanges = true }
                        }

                        NavigationLink(destination: ExercisePickerView(
                            onSelect: { exerciseName in
                                addExercise(name: exerciseName)
                            }
                        )) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.utOrange)
                                Text("Add Exercise")
                                    .font(.headline)
                                    .foregroundColor(.utOrange)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.utOrange.opacity(0.3), lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(.systemBackground))
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 8)

                    // Delete Button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Delete Workout")
                        }
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Workout?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    func bindingForExercise(at index: Int) -> Binding<WorkoutExercise> {
        Binding<WorkoutExercise>(
            get: { exercises[index] },
            set: { exercises[index] = $0 }
        )
    }

    func addExercise(name: String) {
        let newExercise = WorkoutExercise(
            name: name,
            sets: [
                WorkoutSet(reps: "", weight: "", isWarmup: true),
                WorkoutSet(reps: "", weight: "")
            ]
        )
        exercises.append(newExercise)
        hasChanges = true
    }

    func deleteExercise(at index: Int) {
        exercises.remove(at: index)
        hasChanges = true
    }

    func saveChanges() {
        guard hasChanges else { return }

        let updatedWorkout = SavedWorkout(
            id: workout.id,
            name: workoutName.isEmpty ? "Workout" : workoutName,
            date: workout.date,
            exercises: exercises,
            isFavorite: workout.isFavorite
        )

        historyManager.updateWorkout(updatedWorkout)
    }

    func deleteWorkout() {
        historyManager.deleteWorkout(workout)
        presentationMode.wrappedValue.dismiss()
    }
}

struct StatCardSmall: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.utOrange)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WorkoutExerciseDetailCard: View {
    let exercise: WorkoutExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.name)
                .font(.headline)

            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                HStack {
                    Text(setLabel(for: set, at: index))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    Text("\(set.reps) reps")
                        .font(.subheadline)
                        .frame(width: 80, alignment: .leading)

                    Text("\(set.weight) kg")
                        .font(.subheadline)
                        .frame(width: 80, alignment: .leading)

                    Spacer()

                    if set.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private func setLabel(for set: WorkoutSet, at index: Int) -> String {
        if set.isWarmup {
            return "Warmup"
        } else if set.isDropSet {
            return "Drop Set"
        } else {
            return "Set \(index + 1)"
        }
    }
}

// MARK: - Past Workouts Picker

struct PastWorkoutsPickerView: View {
    @ObservedObject var historyManager: WorkoutHistoryManager
    let onSelect: (SavedWorkout) -> Void
    let onDismiss: () -> Void

    private var favoriteWorkouts: [SavedWorkout] {
        historyManager.savedWorkouts.filter { $0.isFavorite }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CustomTabHeader(
                    title: "Favorite Workouts",
                    trailingButton: AnyView(
                        Button("Cancel") {
                            onDismiss()
                        }
                        .foregroundColor(.utOrange)
                        .fontWeight(.semibold)
                    ),
                    isSubScreen: true
                )

                Group {
                    if favoriteWorkouts.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()

                            Image(systemName: "star.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)

                            VStack(spacing: 8) {
                                Text("No Favorite Workouts")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Tap the star icon on any workout to add it to favorites")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }

                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(favoriteWorkouts) { workout in
                                Button(action: {
                                    onSelect(workout)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(workout.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)

                                            HStack(spacing: 16) {
                                                Text(dateString(for: workout.date))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)

                                                Label("\(workout.exercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "star.fill")
                                            .foregroundColor(.utOrange)
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Edit Workout View

struct EditWorkoutView: View {
    let workout: SavedWorkout
    let onDismiss: () -> Void

    @StateObject private var historyManager = WorkoutHistoryManager()
    @State private var workoutName: String
    @State private var exercises: [WorkoutExercise]
    @State private var showDeleteConfirmation = false

    init(workout: SavedWorkout, onDismiss: @escaping () -> Void) {
        self.workout = workout
        self.onDismiss = onDismiss
        _workoutName = State(initialValue: workout.name)
        _exercises = State(initialValue: workout.exercises)
    }

    var totalVolume: Double {
        exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { setTotal, set in
                let weight = Double(set.weight) ?? 0.0
                let reps = Double(set.reps) ?? 0.0
                return setTotal + (weight * reps)
            }
        }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CustomTabHeader(
                    title: "Edit Workout",
                    leadingButton: AnyView(
                        Button("Cancel") {
                            onDismiss()
                        }
                        .foregroundColor(.secondary)
                    ),
                    trailingButton: AnyView(
                        Button("Save") {
                            saveChanges()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.utOrange)
                    ),
                    isSubScreen: true
                )

                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemBackground)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 0) {
                        VStack(spacing: 12) {
                            // Workout Name
                            TextField("Workout Name", text: $workoutName)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.top, 12)

                            // Stats
                            HStack(spacing: 8) {
                                StatCard(title: "Volume", value: String(format: "%.0f kg", totalVolume), icon: "scalemass.fill")
                                StatCard(title: "Sets", value: "\(totalSets)", icon: "number.circle.fill")
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 6)
                        .padding(.top, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(Array(exercises.enumerated()), id: \.element.id) { idx, exercise in
                                ExerciseCard(
                                    exercise: bindingForExercise(at: idx),
                                    exerciseIndex: idx,
                                    onDelete: { deleteExercise(at: idx) },
                                    disabled: false
                                )
                            }

                            NavigationLink(destination: ExercisePickerView(
                                onSelect: { exerciseName in
                                    addExercise(name: exerciseName)
                                }
                            )) {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.utOrange)
                                    Text("Add Exercise")
                                        .font(.headline)
                                        .foregroundColor(.utOrange)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.utOrange.opacity(0.3), lineWidth: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(.systemBackground))
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 12)
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 0)
                        .frame(maxWidth: .infinity)
                    }
                    }
                    .frame(maxWidth: .infinity)

                    // Delete Button at Bottom
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Delete Workout")
                        }
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Delete Workout?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteWorkout()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    func bindingForExercise(at index: Int) -> Binding<WorkoutExercise> {
        Binding<WorkoutExercise>(
            get: { exercises[index] },
            set: { exercises[index] = $0 }
        )
    }

    func addExercise(name: String) {
        let newExercise = WorkoutExercise(
            name: name,
            sets: [
                WorkoutSet(reps: "", weight: "", isWarmup: true),
                WorkoutSet(reps: "", weight: "")
            ]
        )
        exercises.append(newExercise)
    }

    func deleteExercise(at index: Int) {
        exercises.remove(at: index)
    }

    func saveChanges() {
        let updatedWorkout = SavedWorkout(
            id: workout.id,
            name: workoutName.isEmpty ? "Workout" : workoutName,
            date: workout.date,
            exercises: exercises,
            isFavorite: workout.isFavorite
        )

        // Update the workout
        historyManager.updateWorkout(updatedWorkout)

        onDismiss()
    }

    func deleteWorkout() {
        historyManager.deleteWorkout(workout)
        onDismiss()
    }
}

// MARK: - Custom Tab Header

struct CustomTabHeader: View {
    let title: String
    var leadingButton: AnyView?
    var trailingButton: AnyView?
    var isSubScreen: Bool

    init(title: String, leadingButton: AnyView? = nil, trailingButton: AnyView? = nil, isSubScreen: Bool = false) {
        self.title = title
        self.leadingButton = leadingButton
        self.trailingButton = trailingButton
        self.isSubScreen = isSubScreen
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let button = leadingButton {
                button
            }

            Text(title)
                .font(.system(size: isSubScreen ? 22 : 34, weight: isSubScreen ? .semibold : .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer()

            if let button = trailingButton {
                button
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, isSubScreen ? 12 : 8)
        .padding(.bottom, isSubScreen ? 16 : 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Helper Extension

extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
}

#Preview {
    WorkoutsView()
}
