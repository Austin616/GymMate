//
//  ActiveWorkoutPreview.swift
//  fit-texas
//
//  Created by Claude Code on 12/13/25.
//

import SwiftUI

struct ActiveWorkoutPreview: View {
    @ObservedObject var historyManager: WorkoutHistoryManager
    @ObservedObject var timerManager: WorkoutTimerManager
    let onTap: () -> Void

    private var exerciseCount: Int {
        historyManager.currentDraft?.exercises.count ?? 0
    }

    private var completedSets: Int {
        historyManager.currentDraft?.exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.isCompleted }.count
        } ?? 0
    }

    private var totalSets: Int {
        historyManager.currentDraft?.exercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        } ?? 0
    }

    private var elapsedTimeFormatted: String {
        timerManager.formattedElapsedTime()
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 24))
                    .foregroundColor(.utOrange)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.utOrange.opacity(0.1))
                    )

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout in Progress")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text(elapsedTimeFormatted)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.utOrange)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text("\(exerciseCount) exercise\(exerciseCount != 1 ? "s" : "")")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text("\(completedSets)/\(totalSets) sets")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let historyManager = WorkoutHistoryManager()
    historyManager.currentDraft = WorkoutDraft(
        workoutName: "Test Workout",
        startTime: Date(),
        exercises: [
            WorkoutExercise(
                id: UUID(),
                name: "Bench Press",
                sets: [
                    WorkoutSet(id: UUID(), reps: "10", weight: "135", rpe: "7", isCompleted: true, isWarmup: false, isDropSet: false),
                    WorkoutSet(id: UUID(), reps: "8", weight: "145", rpe: "8", isCompleted: true, isWarmup: false, isDropSet: false),
                    WorkoutSet(id: UUID(), reps: "6", weight: "155", rpe: "9", isCompleted: false, isWarmup: false, isDropSet: false)
                ],
                notes: ""
            ),
            WorkoutExercise(
                id: UUID(),
                name: "Squat",
                sets: [
                    WorkoutSet(id: UUID(), reps: "10", weight: "185", rpe: "7", isCompleted: false, isWarmup: false, isDropSet: false)
                ],
                notes: ""
            )
        ],
        lastModified: Date()
    )

    return VStack {
        Spacer()
        ActiveWorkoutPreview(
            historyManager: historyManager,
            timerManager: WorkoutTimerManager.shared,
            onTap: { print("Tapped") }
        )
        .padding(.horizontal, 16)
    }
}
