//
//  Models.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import Foundation

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
