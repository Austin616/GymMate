//
//  NewLogView.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import SwiftUI

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
                    templateWorkout: nil,
                    onSave: {
                        showNewWorkout = false
                        viewMode = .history
                    },
                    onCancel: {
                        showNewWorkout = false
                        viewMode = .history
                    }
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
    let templateWorkout: SavedWorkout?
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var workoutName: String = ""
    @State private var startTime: Date = Date()
    @State private var exercises: [WorkoutExercise] = []
    @State private var showNamePrompt: Bool = false
    @State private var isSaving: Bool = false

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
                    title: "Current Workout",
                    leadingButton: AnyView(
                        Button("Cancel") {
                            onCancel()
                        }
                        .foregroundColor(.secondary)
                    ),
                    trailingButton: AnyView(
                        Button(action: saveWorkout) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .utOrange))
                            } else {
                                Text("Finish")
                                    .fontWeight(.semibold)
                                    .foregroundColor(exercises.isEmpty ? .secondary : .utOrange)
                            }
                        }
                        .disabled(exercises.isEmpty || isSaving)
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
                }
            }
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
            .onAppear {
                loadTemplate()
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
        }
    }

    func saveWorkout() {
        guard !exercises.isEmpty else { return }
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

        historyManager.saveWorkout(workout)
        isSaving = false
        onSave()
    }
}

#Preview {
    NewLogView()
}
