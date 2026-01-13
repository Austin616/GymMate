//
//  FavoritesManager.swift
//  fit-texas
//
//  Created by Claude Code
//

import Foundation
internal import Combine

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    @Published var favoriteExercises: Set<String> = []

    private let favoritesKey = "favoriteExercises"

    private init() {
        loadFavorites()
    }

    func isFavorite(_ exerciseName: String) -> Bool {
        favoriteExercises.contains(exerciseName)
    }

    func toggleFavorite(_ exerciseName: String) {
        if favoriteExercises.contains(exerciseName) {
            favoriteExercises.remove(exerciseName)
        } else {
            favoriteExercises.insert(exerciseName)
        }
        saveFavorites()
    }

    private func saveFavorites() {
        let array = Array(favoriteExercises)
        UserDefaults.standard.set(array, forKey: favoritesKey)
    }

    private func loadFavorites() {
        if let array = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            favoriteExercises = Set(array)
        }
    }
}
