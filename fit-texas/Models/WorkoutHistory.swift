//
//  WorkoutHistory.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import Foundation
internal import Combine

struct SavedWorkout: Identifiable, Codable {
    let id: UUID
    var name: String
    var date: Date
    var exercises: [WorkoutExercise]

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

    init(id: UUID = UUID(), name: String, date: Date, exercises: [WorkoutExercise]) {
        self.id = id
        self.name = name
        self.date = date
        self.exercises = exercises
    }
}

class WorkoutHistoryManager: ObservableObject {
    @Published var savedWorkouts: [SavedWorkout] = []

    private let savePath = FileManager.documentDirectoryPath.appendingPathComponent("workouts.json")

    init() {
        loadWorkouts()
    }

    func saveWorkout(_ workout: SavedWorkout) {
        savedWorkouts.insert(workout, at: 0)
        saveToFile()
    }

    func deleteWorkout(_ workout: SavedWorkout) {
        savedWorkouts.removeAll { $0.id == workout.id }
        saveToFile()
    }

    private func saveToFile() {
        do {
            let data = try JSONEncoder().encode(savedWorkouts)
            try data.write(to: savePath)
        } catch {
            print("Error saving workouts: \(error)")
        }
    }

    private func loadWorkouts() {
        guard FileManager.default.fileExists(atPath: savePath.path) else { return }

        do {
            let data = try Data(contentsOf: savePath)
            savedWorkouts = try JSONDecoder().decode([SavedWorkout].self, from: data)
        } catch {
            print("Error loading workouts: \(error)")
        }
    }
}

extension FileManager {
    static var documentDirectoryPath: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
