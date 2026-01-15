//
//  WorkoutHistory.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import Foundation
internal import Combine

struct WorkoutDraft: Codable, Equatable {
    var workoutName: String
    var startTime: Date
    var exercises: [WorkoutExercise]
    var lastModified: Date

    init(workoutName: String = "", startTime: Date = Date(), exercises: [WorkoutExercise] = [], lastModified: Date = Date()) {
        self.workoutName = workoutName
        self.startTime = startTime
        self.exercises = exercises
        self.lastModified = lastModified
    }
}

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
    static let shared = WorkoutHistoryManager()

    @Published var savedWorkouts: [SavedWorkout] = []
    @Published var isLoading: Bool = false
    @Published var currentDraft: WorkoutDraft?

    private let repository = WorkoutRepository()
    private var cancellables = Set<AnyCancellable>()
    private let draftKey = "currentWorkoutDraft"

    private init() {
        print("🔵 [HISTORY] Initializing WorkoutHistoryManager...")
        observeRepository()
        loadDraft()
        print("✅ [HISTORY] WorkoutHistoryManager initialized")
    }

    private func observeRepository() {
        print("🔵 [HISTORY] Setting up repository observers...")

        repository.$workouts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workouts in
                print("🔵 [HISTORY] Workouts updated: \(workouts.count) workouts")
                self?.savedWorkouts = workouts
            }
            .store(in: &cancellables)

        repository.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
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
        repository.toggleFavorite(workout)
    }

    func updateWorkout(_ workout: SavedWorkout) {
        repository.updateWorkout(workout)
    }

    // MARK: - Draft Management

    func saveDraft(_ draft: WorkoutDraft) {
        print("💾 [DRAFT] Saving workout draft...")
        currentDraft = draft

        if let encoded = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(encoded, forKey: draftKey)
            print("✅ [DRAFT] Draft saved successfully")
        } else {
            print("❌ [DRAFT] Failed to encode draft")
        }
    }

    func loadDraft() {
        print("📂 [DRAFT] Loading workout draft...")
        guard let data = UserDefaults.standard.data(forKey: draftKey),
              let draft = try? JSONDecoder().decode(WorkoutDraft.self, from: data) else {
            print("ℹ️ [DRAFT] No draft found")
            return
        }

        currentDraft = draft
        print("✅ [DRAFT] Draft loaded: \(draft.exercises.count) exercises")
    }

    func clearDraft() {
        print("🗑️ [DRAFT] Clearing workout draft...")
        currentDraft = nil
        UserDefaults.standard.removeObject(forKey: draftKey)
        WorkoutTimerManager.shared.stopWorkout()
        print("✅ [DRAFT] Draft cleared")
    }

    var hasDraft: Bool {
        currentDraft != nil
    }
}

extension FileManager {
    static var documentDirectoryPath: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
