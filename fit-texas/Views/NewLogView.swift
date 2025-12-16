//
//  NewLogView.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import SwiftUI
internal import Combine

enum LogViewMode {
    case history
    case newWorkout
}

struct NewLogView: View {
    @StateObject private var historyManager = WorkoutHistoryManager()
    @State private var viewMode: LogViewMode = .history
    @State private var showNewWorkout = false

    var body: some View {
        NavigationView {
            ZStack {
                if viewMode == .history {
                    WorkoutHistoryView(
                        historyManager: historyManager,
                        onStartNewWorkout: {
                            viewMode = .newWorkout
                            showNewWorkout = true
                        },
                        onImportWorkout: { workout in
                            viewMode = .newWorkout
                            showNewWorkout = true
                        }
                    )
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showNewWorkout) {
                ActiveWorkoutView(
                    historyManager: historyManager,
                    templateWorkout: nil
                )
            }
        }
    }
}

struct WorkoutHistoryView: View {
    @ObservedObject var historyManager: WorkoutHistoryManager
    let onStartNewWorkout: () -> Void
    let onImportWorkout: (SavedWorkout) -> Void

    private func groupedWorkouts() -> [(String, [SavedWorkout])] {
        let grouped = Dictionary(grouping: historyManager.savedWorkouts) { workout -> String in
            let calendar = Calendar.current
            if calendar.isDateInToday(workout.date) {
                return "Today"
            } else if calendar.isDateInYesterday(workout.date) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy"
                return formatter.string(from: workout.date)
            }
        }

        return grouped.sorted { first, second in
            if first.key == "Today" { return true }
            if second.key == "Today" { return false }
            if first.key == "Yesterday" { return true }
            if second.key == "Yesterday" { return false }
            return first.key > second.key
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if historyManager.savedWorkouts.isEmpty {
                EmptyWorkoutHistoryView(onStartNewWorkout: onStartNewWorkout)
            } else {
                List {
                    ForEach(groupedWorkouts(), id: \.0) { section, workouts in
                        Section(header: Text(section)) {
                            ForEach(workouts) { workout in
                                WorkoutHistoryRow(
                                    workout: workout,
                                    onImport: { onImportWorkout(workout) }
                                )
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { index in
                                    historyManager.deleteWorkout(workouts[index])
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                // Floating Action Button (only show when there are workouts)
                Button(action: onStartNewWorkout) {
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
}

struct EmptyWorkoutHistoryView: View {
    let onStartNewWorkout: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundColor(.utOrange.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Workouts Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Start logging your workouts to track your progress")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onStartNewWorkout) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    Text("Start New Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.utOrange)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WorkoutHistoryRow: View {
    let workout: SavedWorkout
    let onImport: () -> Void

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)

                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onImport) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.on.square")
                        Text("Use")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.utOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.utOrange.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundColor(.utOrange)
                    Text("\(workout.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "number.circle")
                        .font(.caption)
                        .foregroundColor(.utOrange)
                    Text("\(workout.totalSets) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "scalemass")
                        .font(.caption)
                        .foregroundColor(.utOrange)
                    Text("\(Int(workout.totalVolume)) kg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActiveWorkoutView: View {
    @ObservedObject var historyManager: WorkoutHistoryManager
    @EnvironmentObject var timerManager: WorkoutTimerManager
    let templateWorkout: SavedWorkout?
    var onFinish: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode

    @State private var workoutName: String = ""
    @State private var startTime: Date = Date()
    @State private var exercises: [WorkoutExercise] = []
    @State private var showNamePrompt: Bool = false
    @State private var isSaving: Bool = false
    @State private var showCancelConfirmation: Bool = false
    @State private var showExercisePicker: Bool = false
    @State private var showExerciseAddedAlert: Bool = false
    @State private var lastAddedExerciseName: String = ""
    @State private var showValidationAlert: Bool = false

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

    var elapsedTime: String {
        timerManager.formattedElapsedTime()
    }

    var canSaveWorkout: Bool {
        // Must have at least one exercise
        guard !exercises.isEmpty else { return false }

        // All exercises must have at least one valid set
        for exercise in exercises {
            guard !exercise.sets.isEmpty else { return false }

            // At least one set must have valid reps AND weight (both non-zero)
            let hasValidSet = exercise.sets.contains { set in
                let reps = Double(set.reps) ?? 0.0
                let weight = Double(set.weight) ?? 0.0
                return reps > 0 && weight > 0
            }

            if !hasValidSet {
                return false
            }
        }

        return true
    }

    var validationMessage: String {
        // Check if no exercises
        if exercises.isEmpty {
            return "Add at least one exercise to save your workout."
        }

        // Check each exercise for valid sets
        for exercise in exercises {
            if exercise.sets.isEmpty {
                return "Exercise '\(exercise.name)' needs at least one set."
            }

            let hasValidSet = exercise.sets.contains { set in
                let reps = Double(set.reps) ?? 0.0
                let weight = Double(set.weight) ?? 0.0
                return reps > 0 && weight > 0
            }

            if !hasValidSet {
                return "Exercise '\(exercise.name)' needs at least one set with both weight and reps filled in."
            }
        }

        return ""
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            // Just go back and save draft
                            if !exercises.isEmpty {
                                saveDraft()
                            }
                            if let onCancel = onCancel {
                                onCancel()
                            } else {
                                presentationMode.wrappedValue.dismiss()
                            }
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

                        HStack(spacing: 16) {
                            Button(action: {
                                showCancelConfirmation = true
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                            }

                            Button(action: {
                                if !canSaveWorkout {
                                    showValidationAlert = true
                                } else {
                                    saveWorkout()
                                }
                            }) {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .utOrange))
                                } else {
                                    Text("Finish")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.utOrange)
                                }
                            }
                            .disabled(isSaving)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    // Centered Timer
                    VStack(spacing: 4) {
                        Text("Current Workout")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(elapsedTime)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.utOrange)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6).opacity(0.3))

                    Divider()
                }
                .background(Color(.systemBackground))

                // Content Section
                VStack(spacing: 0) {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                StatCard(title: "Volume", value: String(format: "%.0f kg", totalVolume), icon: "scalemass.fill")
                                StatCard(title: "Sets", value: "\(totalSets)", icon: "number.circle.fill")
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
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

                            Button(action: {
                                showExercisePicker = true
                            }) {
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
                            .padding(.bottom, 100)

                            NavigationLink(
                                destination: ExercisePickerView(
                                    onSelect: { exerciseName in
                                        addExercise(name: exerciseName)
                                        showExercisePicker = false
                                    }
                                ),
                                isActive: $showExercisePicker
                            ) {
                                EmptyView()
                            }
                            .hidden()
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 0)
                        .frame(maxWidth: .infinity)
                    }
                }
                .background(Color(.systemGray6).opacity(0.3))
            }
            .overlay(
                // Exercise Added Confirmation Toast (overlay at top)
                VStack {
                    if showExerciseAddedAlert {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Exercise Added")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(lastAddedExerciseName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
                , alignment: .top
            )
            .navigationBarHidden(true)
            .alert("Name Your Workout", isPresented: $showNamePrompt) {
                TextField("e.g. Morning Push Day", text: $workoutName)
                Button("Cancel", role: .cancel) {
                    isSaving = false
                }
                Button("Save") {
                    completeWorkoutSave()
                }
            } message: {
                Text("Give your workout a memorable name")
            }
            .alert("Discard Workout?", isPresented: $showCancelConfirmation) {
                Button("Keep Editing", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    // Clear the draft and stop timer
                    timerManager.stopWorkout()
                    historyManager.clearDraft()

                    if let onCancel = onCancel {
                        onCancel()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text("Your workout will not be saved.")
            }
            .alert("Cannot Save Workout", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                loadTemplate()
                // Start workout timer if not already running
                if timerManager.workoutStartTime == nil {
                    timerManager.startWorkout(startTime: startTime)
                }
            }
            .onChange(of: exercises) { _ in
                // Auto-save draft when exercises change
                if !exercises.isEmpty {
                    saveDraft()
                }
            }
        }
        .navigationViewStyle(.stack)
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
                WorkoutSet(reps: "", weight: "")
            ]
        )

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            exercises.append(newExercise)
        }

        // Show confirmation toast with animation
        lastAddedExerciseName = name
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showExerciseAddedAlert = true
        }

        // Hide alert after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showExerciseAddedAlert = false
            }
        }
    }

    func deleteExercise(at index: Int) {
        exercises.remove(at: index)
    }

    func loadTemplate() {
        if let template = templateWorkout {
            // Load exercises from template but reset completion status
            exercises = template.exercises.map { exercise in
                WorkoutExercise(
                    name: exercise.name,
                    sets: exercise.sets.map { set in
                        WorkoutSet(
                            reps: set.reps,
                            weight: set.weight,
                            rpe: set.rpe,
                            isCompleted: false,
                            isWarmup: set.isWarmup,
                            isDropSet: set.isDropSet
                        )
                    },
                    notes: exercise.notes
                )
            }
        } else if let draft = historyManager.currentDraft {
            // Load from draft if no template
            workoutName = draft.workoutName
            startTime = draft.startTime
            exercises = draft.exercises
            print("✅ [DRAFT] Loaded draft with \(draft.exercises.count) exercises")
        }
    }

    func saveDraft() {
        let draft = WorkoutDraft(
            workoutName: workoutName,
            startTime: startTime,
            exercises: exercises,
            lastModified: Date()
        )
        historyManager.saveDraft(draft)
    }

    func saveWorkout() {
        guard canSaveWorkout else { return }
        isSaving = true
        showNamePrompt = true
    }

    func completeWorkoutSave() {
        let finalName = workoutName.isEmpty ? "Workout" : workoutName

        let workout = SavedWorkout(
            name: finalName,
            date: Date(),
            exercises: exercises
        )

        // Stop timer and clear Live Activity immediately
        timerManager.stopWorkout()

        // Clear draft to hide preview instantly
        historyManager.clearDraft()

        // Save workout to history
        historyManager.saveWorkout(workout)

        isSaving = false

        if let onFinish = onFinish {
            onFinish()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    NewLogView()
        .environmentObject(WorkoutTimerManager.shared)
}
