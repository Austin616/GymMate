//
//  LogView.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI

struct LogView: View {
    @State private var workoutName: String = "Log Workout"
    @State private var startTime: Date = Date()
    @State private var exercises: [WorkoutExercise] = []
    @State private var showSuccess: Bool = false
    @State private var isSaving: Bool = false
    @State private var showWorkoutNameEditor: Bool = false

    // Computed properties for workout stats
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
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray6), Color(.systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Top bar and stat cards
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
                        
                        // Stats cards
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
                    
                    // Exercises List
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
            .navigationBarHidden(true)
            .alert("Workout Name", isPresented: $showWorkoutNameEditor) {
                TextField("Enter workout name", text: $workoutName)
                Button("Cancel", role: .cancel) { }
                Button("Save") { }
            }
            .alert(isPresented: $showSuccess) {
                Alert(
                    title: Text("Workout Saved!"),
                    message: Text("Your workout has been logged successfully."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Bindings

    func bindingForExercise(at index: Int) -> Binding<WorkoutExercise> {
        Binding<WorkoutExercise>(
            get: { exercises[index] },
            set: { exercises[index] = $0 }
        )
    }

    // MARK: - Actions

    func addExercise(name: String) {
        let newExercise = WorkoutExercise(
            name: name,
            sets: [
                WorkoutSet(reps: "", weight: "", rpe: "", isCompleted: false, isWarmup: true, isDropSet: false),
                WorkoutSet(reps: "", weight: "", rpe: "", isCompleted: false, isWarmup: false, isDropSet: false)
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

        // TODO: Implement Firebase/backend save logic here if needed

        isSaving = false
        showSuccess = true
    }
}

#Preview {
    LogView()
        .environmentObject(WorkoutTimerManager.shared)
}
