//
//  ExercisePickerView.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI

struct ExercisePickerView: View {
    let allExercises: [String]
    let onSelect: (String) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @State private var searchText: String = ""

    var filteredExercises: [String] {
        if searchText.isEmpty {
            return allExercises
        }
        return allExercises.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredExercises, id: \.self) { ex in
                    Button(action: {
                        onSelect(ex)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.utOrange.opacity(0.15))
                                    .frame(width: 30, height: 30)
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.caption)
                                    .foregroundColor(.utOrange)
                            }
                            
                            Text(ex)
                                .foregroundColor(.primary)
                                .font(.body)
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.utOrange)
                                .font(.title3)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.utOrange)
                }
            }
        }
    }
}

// MARK: - Sample Data

let sampleExercises = [
    "Bench Press (Barbell)",
    "Squat (Barbell)",
    "Deadlift (Barbell)",
    "Overhead Press (Barbell)",
    "Bent Over Row (Barbell)",
    "Pull-ups",
    "Dips",
    "Leg Press",
    "Lat Pulldown",
    "Cable Flyes",
    "Bicep Curls (Dumbbell)",
    "Tricep Extensions",
    "Lunges",
    "Romanian Deadlift",
    "Chest Press (Machine)"
]
