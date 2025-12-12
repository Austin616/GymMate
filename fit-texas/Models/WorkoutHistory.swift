//
//  WorkoutHistory.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import Foundation
internal import Combine

struct SavedWorkout: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var date: Date
    var exercises: [WorkoutExercise]
    var isFavorite: Bool

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

    init(id: UUID = UUID(), name: String, date: Date, exercises: [WorkoutExercise], isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.date = date
        self.exercises = exercises
        self.isFavorite = isFavorite
    }

    // Custom decoder to handle missing isFavorite field in old workouts
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        date = try container.decode(Date.self, forKey: .date)
        exercises = try container.decode([WorkoutExercise].self, forKey: .exercises)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
}

class WorkoutHistoryManager: ObservableObject {
    @Published var savedWorkouts: [SavedWorkout] = []
    @Published var isOnline: Bool = true
    @Published var isSyncing: Bool = false

    private let repository = WorkoutRepository()
    private var cancellables = Set<AnyCancellable>()

    init() {
        print("🔵 [HISTORY] Initializing WorkoutHistoryManager...")
        observeRepository()
        print("✅ [HISTORY] WorkoutHistoryManager initialized")
    }

    private func observeRepository() {
        print("🔵 [HISTORY] Setting up repository observers...")

        repository.$workouts
            .sink { [weak self] workouts in
                print("🔵 [HISTORY] Workouts updated: \(workouts.count) workouts")
                self?.savedWorkouts = workouts
            }
            .store(in: &cancellables)

        repository.$isOnline
            .sink { [weak self] online in
                print("🔵 [HISTORY] Online status: \(online)")
                self?.isOnline = online
            }
            .store(in: &cancellables)

        repository.$isSyncing
            .sink { [weak self] syncing in
                print("🔵 [HISTORY] Syncing status: \(syncing)")
                self?.isSyncing = syncing
            }
            .store(in: &cancellables)
    }

    func saveWorkout(_ workout: SavedWorkout) {
        repository.saveWorkout(workout)
    }

    func deleteWorkout(_ workout: SavedWorkout) {
        repository.deleteWorkout(workout)
    }

    func toggleFavorite(_ workout: SavedWorkout) {
        var updatedWorkout = workout
        updatedWorkout.isFavorite.toggle()

        // Update workout (saveWorkout will overwrite the existing one)
        repository.saveWorkout(updatedWorkout)
    }

    func updateWorkout(_ workout: SavedWorkout) {
        repository.saveWorkout(workout)
    }

    func syncAllWorkouts() {
        repository.syncAllWorkouts()
    }
}

extension FileManager {
    static var documentDirectoryPath: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
