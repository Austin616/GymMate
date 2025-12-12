//
//  WorkoutRepository.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
internal import Combine

class WorkoutRepository: ObservableObject {
    @Published var workouts: [SavedWorkout] = []
    @Published var isOnline: Bool = true
    @Published var isSyncing: Bool = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let localStorageManager = LocalWorkoutStorage()

    init() {
        print("🔵 [REPO] Initializing WorkoutRepository...")

        // Enable offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
        print("✅ [REPO] Firestore offline persistence enabled")

        loadWorkouts()
        setupRealtimeListener()

        print("✅ [REPO] WorkoutRepository initialized")
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Load Workouts

    func loadWorkouts() {
        guard let userId = Auth.auth().currentUser?.uid else {
            // Not logged in, load from local only
            workouts = localStorageManager.loadWorkouts()
            return
        }

        // Try to load from Firestore first
        fetchFromFirestore(userId: userId) { [weak self] success in
            if !success {
                // Offline or error, load from local cache
                self?.workouts = self?.localStorageManager.loadWorkouts() ?? []
            }
        }
    }

    // MARK: - Save Workout

    func saveWorkout(_ workout: SavedWorkout) {
        print("🔵 [SAVE] Starting save for workout: \(workout.name)")
        print("🔵 [SAVE] Workout ID: \(workout.id)")
        print("🔵 [SAVE] Exercises count: \(workout.exercises.count)")

        // 1. Save locally first (offline-first)
        // Check if workout already exists and update it, otherwise insert new
        if let existingIndex = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[existingIndex] = workout
            print("🔵 [SAVE] Updated existing workout")
        } else {
            workouts.insert(workout, at: 0)
            print("🔵 [SAVE] Inserted new workout")
        }
        localStorageManager.saveWorkouts(workouts)
        print("✅ [SAVE] Saved locally. Total workouts: \(workouts.count)")

        // 2. Try to sync to Firestore
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ [SAVE] Not logged in, saved locally only")
            return
        }

        print("🔵 [SAVE] User ID: \(userId)")
        syncToFirestore(workout: workout, userId: userId)
    }

    // MARK: - Delete Workout

    func deleteWorkout(_ workout: SavedWorkout) {
        // 1. Delete locally first
        workouts.removeAll { $0.id == workout.id }
        localStorageManager.saveWorkouts(workouts)

        // 2. Try to delete from Firestore
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(userId)
            .collection("workouts")
            .document(workout.id.uuidString)
            .delete() { error in
                if let error = error {
                    print("❌ Error deleting from Firestore: \(error)")
                } else {
                    print("✅ Deleted from Firestore: \(workout.id)")
                }
            }
    }

    // MARK: - Firestore Operations

    private func fetchFromFirestore(userId: String, completion: @escaping (Bool) -> Void) {
        isSyncing = true

        db.collection("users")
            .document(userId)
            .collection("workouts")
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, error in
                self?.isSyncing = false

                if let error = error {
                    print("❌ Error fetching from Firestore: \(error)")
                    self?.isOnline = false
                    completion(false)
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(false)
                    return
                }

                self?.isOnline = true

                do {
                    let fetchedWorkouts = try documents.compactMap { doc -> SavedWorkout? in
                        try doc.data(as: SavedWorkout.self)
                    }

                    self?.workouts = fetchedWorkouts
                    self?.localStorageManager.saveWorkouts(fetchedWorkouts)

                    print("✅ Fetched \(fetchedWorkouts.count) workouts from Firestore")
                    completion(true)
                } catch {
                    print("❌ Error decoding workouts: \(error)")
                    completion(false)
                }
            }
    }

    private func syncToFirestore(workout: SavedWorkout, userId: String) {
        print("🔵 [FIRESTORE] Starting Firestore sync...")
        isSyncing = true

        do {
            let docPath = "users/\(userId)/workouts/\(workout.id.uuidString)"
            print("🔵 [FIRESTORE] Document path: \(docPath)")

            try db.collection("users")
                .document(userId)
                .collection("workouts")
                .document(workout.id.uuidString)
                .setData(from: workout) { [weak self] error in
                    self?.isSyncing = false

                    if let error = error {
                        print("❌ [FIRESTORE] Error syncing: \(error.localizedDescription)")
                        print("❌ [FIRESTORE] Full error: \(error)")
                        self?.isOnline = false
                    } else {
                        print("✅ [FIRESTORE] Successfully synced workout: \(workout.name)")
                        self?.isOnline = true
                    }
                }
        } catch {
            isSyncing = false
            print("❌ [FIRESTORE] Error encoding workout: \(error)")
        }
    }

    // MARK: - Real-time Listener

    private func setupRealtimeListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        listener = db.collection("users")
            .document(userId)
            .collection("workouts")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Listener error: \(error)")
                    self.isOnline = false
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.isOnline = true

                do {
                    let fetchedWorkouts = try documents.compactMap { doc -> SavedWorkout? in
                        try doc.data(as: SavedWorkout.self)
                    }

                    self.workouts = fetchedWorkouts
                    self.localStorageManager.saveWorkouts(fetchedWorkouts)

                    print("🔄 Real-time update: \(fetchedWorkouts.count) workouts")
                } catch {
                    print("❌ Error decoding workouts: \(error)")
                }
            }
    }

    // MARK: - Manual Sync

    func syncAllWorkouts() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isSyncing = true

        let batch = db.batch()

        for workout in workouts {
            let docRef = db.collection("users")
                .document(userId)
                .collection("workouts")
                .document(workout.id.uuidString)

            do {
                try batch.setData(from: workout, forDocument: docRef)
            } catch {
                print("❌ Error encoding workout \(workout.id): \(error)")
            }
        }

        batch.commit { [weak self] error in
            self?.isSyncing = false

            if let error = error {
                print("❌ Batch sync error: \(error)")
            } else {
                print("✅ Synced all workouts to Firestore")
            }
        }
    }
}

// MARK: - Local Storage Manager

class LocalWorkoutStorage {
    private let savePath = FileManager.documentDirectoryPath.appendingPathComponent("workouts.json")

    func saveWorkouts(_ workouts: [SavedWorkout]) {
        do {
            let data = try JSONEncoder().encode(workouts)
            try data.write(to: savePath)
            print("💾 Saved \(workouts.count) workouts locally")
        } catch {
            print("❌ Error saving locally: \(error)")
        }
    }

    func loadWorkouts() -> [SavedWorkout] {
        guard FileManager.default.fileExists(atPath: savePath.path) else {
            print("📂 No local workouts file found")
            return []
        }

        do {
            let data = try Data(contentsOf: savePath)
            let workouts = try JSONDecoder().decode([SavedWorkout].self, from: data)
            print("💾 Loaded \(workouts.count) workouts from local storage")
            return workouts
        } catch {
            print("❌ Error loading locally: \(error)")
            return []
        }
    }
}
