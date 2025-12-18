//
//  ActiveWorkoutPreview.swift
//  fit-texas
//
//  Created by Claude Code on 12/13/25.
//

import SwiftUI

// MARK: - Full Screen Preview (for Log tab when workout is active)
struct ActiveWorkoutPreviewScreen: View {
    @ObservedObject var historyManager: WorkoutHistoryManager
    @EnvironmentObject var timerManager: WorkoutTimerManager
    @ObservedObject private var settingsManager = SettingsManager.shared
    let onResume: () -> Void

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

    private var totalVolume: Double {
        historyManager.currentDraft?.exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { setTotal, set in
                let weight = Double(set.weight) ?? 0.0
                let reps = Double(set.reps) ?? 0.0
                return setTotal + (weight * reps)
            }
        } ?? 0.0
    }

    private var elapsedTimeFormatted: String {
        timerManager.formattedElapsedTime()
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomTabHeader(title: "Workouts")

            VStack(spacing: 32) {
                Spacer()

                // Green circle with icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.green.opacity(0.3), radius: 20, x: 0, y: 10)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                // Workout Info
                VStack(spacing: 12) {
                    Text("Workout in Progress")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    // Timer
                    Text(elapsedTimeFormatted)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .monospacedDigit()
                }

                // Stats Cards
                HStack(spacing: 16) {
                    StatPreviewCard(
                        title: "Exercises",
                        value: "\(exerciseCount)",
                        icon: "dumbbell.fill"
                    )

                    StatPreviewCard(
                        title: "Sets",
                        value: "\(completedSets)/\(totalSets)",
                        icon: "number.circle.fill"
                    )

                    StatPreviewCard(
                        title: "Volume",
                        value: String(format: "%.0f \(settingsManager.weightUnit.rawValue)", totalVolume),
                        icon: "scalemass.fill"
                    )
                }
                .padding(.horizontal)

                Spacer()

                // Resume Button
                Button(action: onResume) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("Resume Workout")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green)
                            .shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 6)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 120)
            }
        }
    }
}

struct StatPreviewCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.utOrange)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Floating Preview (for tab bar)
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
    VStack {
        Spacer()
        ActiveWorkoutPreview(
            historyManager: WorkoutHistoryManager.shared,
            timerManager: WorkoutTimerManager.shared,
            onTap: { print("Tapped") }
        )
        .padding(.horizontal, 16)
    }
    .onAppear {
        WorkoutHistoryManager.shared.currentDraft = WorkoutDraft(
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
    }
}
