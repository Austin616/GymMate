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
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showNewWorkout) {
                ActiveWorkoutView(
                    historyManager: historyManager,
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
            }

            // Floating Action Button
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

struct EmptyWorkoutHistoryView: View {
    let onStartNewWorkout: () -> Void

    var body: some View {
        VStack(spacing: 20) {
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
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Start New Workout")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.utOrange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
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
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var workoutName: String = "Workout"
    @State private var startTime: Date = Date()
    @State private var exercises: [WorkoutExercise] = []
    @State private var showSuccess: Bool = false
    @State private var isSaving: Bool = false
    @State private var showWorkoutNameEditor: Bool = false

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
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray6), Color(.systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        HStack {
                            Button(action: { showWorkoutNameEditor = true }) {
                                HStack(spacing: 6) {
                                    Text(workoutName)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Image(systemName: "chevron.down.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.utOrange)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemBackground))
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(action: saveWorkout) {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(width: 90, height: 38)
                                } else {
                                    Text("Finish")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 90, height: 38)
                                }
                            }
                            .background(exercises.isEmpty ? Color.gray.opacity(0.5) : .utOrange)
                            .clipShape(Capsule())
                            .shadow(color: exercises.isEmpty ? Color.clear : Color.utOrange.opacity(0.3), radius: 3, x: 0, y: 2)
                            .disabled(exercises.isEmpty || isSaving)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 12)

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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .alert("Workout Name", isPresented: $showWorkoutNameEditor) {
                TextField("Enter workout name", text: $workoutName)
                Button("Cancel", role: .cancel) { }
                Button("Save") { }
            }
            .alert(isPresented: $showSuccess) {
                Alert(
                    title: Text("Workout Saved!"),
                    message: Text("Your workout has been logged successfully."),
                    dismissButton: .default(Text("OK")) {
                        onSave()
                    }
                )
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

    func saveWorkout() {
        guard !exercises.isEmpty else { return }

        isSaving = true

        let workout = SavedWorkout(
            name: workoutName,
            date: Date(),
            exercises: exercises
        )

        historyManager.saveWorkout(workout)

        isSaving = false
        showSuccess = true
    }
}

#Preview {
    NewLogView()
}
