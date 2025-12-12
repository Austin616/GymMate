//
//  Models.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import Foundation

// MARK: - Exercise Database Models

struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let force: String?
    let level: String?
    let mechanic: String?
    let equipment: String?
    let primaryMuscles: [String]?
    let secondaryMuscles: [String]?
    let instructions: [String]?
    let category: String?
    let images: [String]?
}

// MARK: - Workout Models

struct WorkoutExercise: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var sets: [WorkoutSet]
    var notes: String

    init(id: UUID = UUID(), name: String, sets: [WorkoutSet], notes: String = "") {
        self.id = id
        self.name = name
        self.sets = sets
        self.notes = notes
    }
}

struct WorkoutSet: Identifiable, Hashable, Codable {
    let id: UUID
    var reps: String
    var weight: String
    var rpe: String
    var isCompleted: Bool
    var isWarmup: Bool
    var isDropSet: Bool

    init(id: UUID = UUID(), reps: String, weight: String, rpe: String = "", isCompleted: Bool = false, isWarmup: Bool = false, isDropSet: Bool = false) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.isCompleted = isCompleted
        self.isWarmup = isWarmup
        self.isDropSet = isDropSet
    }
}
