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
    @Published var isLoading: Bool = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() {
        print("🔵 [REPO] Initializing WorkoutRepository...")
        setupAuthListener()
        print("✅ [REPO] WorkoutRepository initialized")
    }

    deinit {
        listener?.remove()
    }
    
    // MARK: - Auth Listener
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.setupRealtimeListener(userId: user.uid)
            } else {
                print("🧹 [REPO] Removing workout listener")
                self?.listener?.remove()
                self?.listener = nil
                DispatchQueue.main.async {
                    self?.workouts = []
                }
            }
        }
    }

    // MARK: - Real-time Listener (Primary data source)

    private func setupRealtimeListener(userId: String) {
        listener?.remove()
        isLoading = true
        
        print("🔵 [REPO] Setting up real-time listener for user: \(userId)")

        listener = db.collection("users")
            .document(userId)
            .collection("workouts")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.isLoading = false
                }

                if let error = error {
                    print("❌ [REPO] Listener error: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ [REPO] No documents found")
                    return
                }

                do {
                    let fetchedWorkouts = try documents.compactMap { doc -> SavedWorkout? in
                        try doc.data(as: SavedWorkout.self)
                    }

                    DispatchQueue.main.async {
                        self.workouts = fetchedWorkouts
                    }
                    
                    print("✅ [REPO] Loaded \(fetchedWorkouts.count) workouts from Firestore")
                } catch {
                    print("❌ [REPO] Error decoding workouts: \(error)")
                }
            }
    }

    // MARK: - Save Workout

    func saveWorkout(_ workout: SavedWorkout) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ [REPO] Cannot save - not logged in")
            return
        }
        
        print("🔵 [REPO] Saving workout: \(workout.name)")

        do {
            try db.collection("users")
                .document(userId)
                .collection("workouts")
                .document(workout.id.uuidString)
                .setData(from: workout) { error in
                    if let error = error {
                        print("❌ [REPO] Error saving workout: \(error)")
                    } else {
                        print("✅ [REPO] Saved workout: \(workout.name)")
                    }
                }
        } catch {
            print("❌ [REPO] Error encoding workout: \(error)")
        }
    }
    
    // MARK: - Update Workout
    
    func updateWorkout(_ workout: SavedWorkout) {
        saveWorkout(workout) // Same operation - setData with merge
    }

    // MARK: - Delete Workout

    func deleteWorkout(_ workout: SavedWorkout) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ [REPO] Cannot delete - not logged in")
            return
        }
        
        print("🔵 [REPO] Deleting workout: \(workout.name)")

        db.collection("users")
            .document(userId)
            .collection("workouts")
            .document(workout.id.uuidString)
            .delete { error in
                if let error = error {
                    print("❌ [REPO] Error deleting workout: \(error)")
                } else {
                    print("✅ [REPO] Deleted workout: \(workout.name)")
                }
            }
    }
    
    // MARK: - Toggle Favorite
    
    func toggleFavorite(_ workout: SavedWorkout) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("workouts")
            .document(workout.id.uuidString)
            .updateData(["isFavorite": !workout.isFavorite]) { error in
                if let error = error {
                    print("❌ [REPO] Error toggling favorite: \(error)")
                } else {
                    print("✅ [REPO] Toggled favorite for: \(workout.name)")
                }
            }
    }
}
