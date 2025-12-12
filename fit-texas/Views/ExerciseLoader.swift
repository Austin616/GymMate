//
//  ExerciseLoader.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import Foundation

class ExerciseLoader {
    static let shared = ExerciseLoader()

    private var exercises: [Exercise] = []

    private init() {
        loadExercises()
    }

    func loadExercises() {
        // Load from single exercises.json file
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            print("❌ Error: Could not find exercises.json in bundle")
            print("Bundle path: \(Bundle.main.bundlePath)")
            loadFallbackExercises()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            exercises = try decoder.decode([Exercise].self, from: data)

            // Sort exercises alphabetically by name
            exercises.sort { $0.name < $1.name }

            print("✅ Successfully loaded \(exercises.count) exercises from exercises.json")
        } catch {
            print("❌ Error loading exercises.json: \(error)")
            loadFallbackExercises()
        }
    }

    private func loadFallbackExercises() {
        // Fallback exercises if JSON files aren't found
        let fallbackNames = [
            "Bench Press",
            "Squat",
            "Deadlift",
            "Overhead Press",
            "Bent Over Row",
            "Pull-ups",
            "Dips",
            "Leg Press",
            "Lat Pulldown",
            "Bicep Curls",
            "Tricep Extensions",
            "Lunges",
            "Romanian Deadlift"
        ]

        exercises = fallbackNames.map { name in
            Exercise(
                id: name.replacingOccurrences(of: " ", with: "_"),
                name: name,
                force: nil,
                level: nil,
                mechanic: nil,
                equipment: nil,
                primaryMuscles: nil,
                secondaryMuscles: nil,
                instructions: nil,
                category: nil,
                images: nil
            )
        }
    }

    func getAllExercises() -> [Exercise] {
        return exercises
    }

    func getExerciseNames() -> [String] {
        return exercises.map { $0.name }
    }

    func getExercise(byName name: String) -> Exercise? {
        return exercises.first { $0.name == name }
    }

    func searchExercises(query: String) -> [Exercise] {
        if query.isEmpty {
            return exercises
        }
        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(query) ||
            exercise.primaryMuscles?.contains(where: { $0.localizedCaseInsensitiveContains(query) }) == true ||
            exercise.equipment?.localizedCaseInsensitiveContains(query) == true
        }
    }

    func getMuscleGroups() -> [String] {
        var muscleSet = Set<String>()

        for exercise in exercises {
            if let primaryMuscles = exercise.primaryMuscles {
                for muscle in primaryMuscles {
                    muscleSet.insert(muscle.capitalized)
                }
            }
        }

        return muscleSet.sorted()
    }

    func getExercises(forMuscleGroup muscle: String) -> [Exercise] {
        return exercises.filter { exercise in
            exercise.primaryMuscles?.contains(where: {
                $0.lowercased() == muscle.lowercased()
            }) == true
        }
    }
}
