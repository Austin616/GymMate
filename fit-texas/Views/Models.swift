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

struct WorkoutExercise: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var sets: [WorkoutSet]
    var notes: String = ""
}

struct WorkoutSet: Identifiable, Hashable {
    let id = UUID()
    var reps: String
    var weight: String
    var rpe: String = ""
    var isCompleted: Bool = false
    var isWarmup: Bool = false
    var isDropSet: Bool = false
}
