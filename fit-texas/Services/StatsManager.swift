//
//  StatsManager.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import Foundation
internal import Combine

struct WorkoutStats {
    let totalWorkouts: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalVolume: Double
    let totalSets: Int
    let totalExercises: Int
    let favoriteExercise: String?
    let workoutsThisWeek: Int
    let workoutsThisMonth: Int
}

class StatsManager: ObservableObject {
    @Published var stats: WorkoutStats = WorkoutStats(
        totalWorkouts: 0,
        currentStreak: 0,
        longestStreak: 0,
        totalVolume: 0,
        totalSets: 0,
        totalExercises: 0,
        favoriteExercise: nil,
        workoutsThisWeek: 0,
        workoutsThisMonth: 0
    )

    private var cancellables = Set<AnyCancellable>()

    func calculateStats(from workouts: [SavedWorkout]) {
        let totalWorkouts = workouts.count

        let currentStreak = calculateCurrentStreak(from: workouts)
        let longestStreak = calculateLongestStreak(from: workouts)

        let totalVolume = workouts.reduce(0.0) { $0 + $1.totalVolume }
        let totalSets = workouts.reduce(0) { $0 + $1.totalSets }

        let totalExercises = workouts.reduce(0) { total, workout in
            total + workout.exercises.count
        }

        let favoriteExercise = findFavoriteExercise(from: workouts)

        let workoutsThisWeek = countWorkouts(in: .weekOfYear, from: workouts)
        let workoutsThisMonth = countWorkouts(in: .month, from: workouts)

        stats = WorkoutStats(
            totalWorkouts: totalWorkouts,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalVolume: totalVolume,
            totalSets: totalSets,
            totalExercises: totalExercises,
            favoriteExercise: favoriteExercise,
            workoutsThisWeek: workoutsThisWeek,
            workoutsThisMonth: workoutsThisMonth
        )
    }

    func observeWorkouts(from repository: WorkoutRepository) {
        repository.$workouts
            .sink { [weak self] workouts in
                self?.calculateStats(from: workouts)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Helpers

    private func calculateCurrentStreak(from workouts: [SavedWorkout]) -> Int {
        guard !workouts.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique workout dates sorted descending
        let workoutDates = Set(workouts.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >)

        var streak = 0
        var currentDate = today

        // Check if there's a workout today or yesterday to start the streak
        if !workoutDates.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  workoutDates.contains(yesterday) else {
                return 0
            }
            currentDate = yesterday
        }

        // Count consecutive days
        for date in workoutDates {
            if date == currentDate {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else if date < currentDate {
                break
            }
        }

        return streak
    }

    private func calculateLongestStreak(from workouts: [SavedWorkout]) -> Int {
        guard !workouts.isEmpty else { return 0 }

        let calendar = Calendar.current

        let workoutDates = Set(workouts.map { calendar.startOfDay(for: $0.date) })
            .sorted()

        var longestStreak = 0
        var currentStreak = 0
        var lastDate: Date?

        for date in workoutDates {
            if let last = lastDate {
                let daysBetween = calendar.dateComponents([.day], from: last, to: date).day ?? 0

                if daysBetween == 1 {
                    currentStreak += 1
                } else {
                    longestStreak = max(longestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }

            lastDate = date
        }

        longestStreak = max(longestStreak, currentStreak)
        return longestStreak
    }

    private func findFavoriteExercise(from workouts: [SavedWorkout]) -> String? {
        var exerciseCounts: [String: Int] = [:]

        for workout in workouts {
            for exercise in workout.exercises {
                exerciseCounts[exercise.name, default: 0] += 1
            }
        }

        return exerciseCounts.max(by: { $0.value < $1.value })?.key
    }

    private func countWorkouts(in period: Calendar.Component, from workouts: [SavedWorkout]) -> Int {
        let calendar = Calendar.current
        let now = Date()

        if period == .weekOfYear {
            // Special handling for week
            let startOfWeek = now.startOfWeek
            guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
                return 0
            }

            return workouts.filter { workout in
                workout.date >= startOfWeek && workout.date < endOfWeek
            }.count
        } else {
            return workouts.filter { workout in
                calendar.isDate(workout.date, equalTo: now, toGranularity: period)
            }.count
        }
    }

    // MARK: - Formatted Stats

    func formattedVolume() -> String {
        if stats.totalVolume >= 1000 {
            return String(format: "%.1fk", stats.totalVolume / 1000)
        } else {
            return String(format: "%.0f", stats.totalVolume)
        }
    }

    func formattedStats() -> (workouts: String, streak: String, volume: String) {
        return (
            workouts: "\(stats.totalWorkouts)",
            streak: "\(stats.currentStreak)",
            volume: formattedVolume()
        )
    }
}
