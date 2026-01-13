//
//  ShareWorkoutSheet.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI

struct ShareWorkoutSheet: View {
    let workout: SavedWorkout
    let duration: TimeInterval?
    let onShare: (String?, TimeInterval?) async -> Void
    let onSkip: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var caption = ""
    @State private var isSharing = false
    @State private var editedDuration: TimeInterval
    @State private var showDurationPicker = false
    
    init(workout: SavedWorkout, duration: TimeInterval?, onShare: @escaping (String?, TimeInterval?) async -> Void, onSkip: @escaping () -> Void) {
        self.workout = workout
        self.duration = duration
        self.onShare = onShare
        self.onSkip = onSkip
        self._editedDuration = State(initialValue: duration ?? 0)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Skip") {
                        onSkip()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Share Workout")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: shareWorkout) {
                        if isSharing {
                            ProgressView()
                        } else {
                            Text("Share")
                                .fontWeight(.semibold)
                                .foregroundColor(.utOrange)
                        }
                    }
                    .disabled(isSharing)
                }
                .padding()
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Workout Preview Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.name)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    
                                    Text(formattedDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            // Duration Section (Editable)
                            Button(action: { showDurationPicker = true }) {
                                HStack {
                                    Image(systemName: "timer")
                                        .font(.title3)
                                        .foregroundColor(.utOrange)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Workout Duration")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(formatDuration(editedDuration))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.utOrange)
                                }
                                .padding()
                                .background(Color.utOrange.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            
                            // Stats
                            HStack(spacing: 0) {
                                ShareStatItem(value: "\(workout.exercises.count)", label: "Exercises", icon: "figure.strengthtraining.traditional")
                                
                                Divider()
                                    .frame(height: 40)
                                
                                ShareStatItem(value: "\(workout.totalSets)", label: "Sets", icon: "number.circle.fill")
                                
                                Divider()
                                    .frame(height: 40)
                                
                                ShareStatItem(value: "\(Int(workout.totalVolume))", label: "kg", icon: "scalemass.fill")
                            }
                            
                            // Exercise List Preview
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(workout.exercises.prefix(4)) { exercise in
                                    HStack {
                                        Text(exercise.name)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text("\(exercise.sets.count) sets")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if workout.exercises.count > 4 {
                                    Text("+ \(workout.exercises.count - 4) more exercises")
                                        .font(.caption)
                                        .foregroundColor(.utOrange)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Caption Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add a caption")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            TextField("How was your workout?", text: $caption, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                        
                        // Info
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            
                            Text("Your workout will be visible to everyone on campus")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showDurationPicker) {
            DurationPickerSheet(duration: $editedDuration)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func shareWorkout() {
        isSharing = true
        
        Task {
            await onShare(caption.isEmpty ? nil : caption, editedDuration)
            
            await MainActor.run {
                isSharing = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Duration Picker Sheet

struct DurationPickerSheet: View {
    @Binding var duration: TimeInterval
    @Environment(\.dismiss) private var dismiss
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Edit Workout Duration")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 24)
                
                // Duration Display
                Text(formattedDuration)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.utOrange)
                
                // Pickers
                HStack(spacing: 0) {
                    // Hours
                    VStack {
                        Text("Hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 150)
                        .clipped()
                    }
                    
                    Text(":")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Minutes
                    VStack {
                        Text("Min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { min in
                                Text(String(format: "%02d", min)).tag(min)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 150)
                        .clipped()
                    }
                    
                    Text(":")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Seconds
                    VStack {
                        Text("Sec")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { sec in
                                Text(String(format: "%02d", sec)).tag(sec)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 150)
                        .clipped()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    duration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                    dismiss()
                }) {
                    Text("Save Duration")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.utOrange)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.utOrange)
                }
            }
        }
        .onAppear {
            hours = Int(duration) / 3600
            minutes = (Int(duration) % 3600) / 60
            seconds = Int(duration) % 60
        }
    }
    
    private var formattedDuration: String {
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Share Stat Item

struct ShareStatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.utOrange)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Share Workout Prompt Modifier

struct ShareWorkoutPromptModifier: ViewModifier {
    @Binding var isPresented: Bool
    let workout: SavedWorkout?
    let duration: TimeInterval?
    let onShare: (String?, TimeInterval?) async -> Void
    let onSkip: () -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                if let workout = workout {
                    ShareWorkoutSheet(
                        workout: workout,
                        duration: duration,
                        onShare: onShare,
                        onSkip: onSkip
                    )
                    .presentationDetents([.medium, .large])
                }
            }
    }
}

extension View {
    func shareWorkoutPrompt(
        isPresented: Binding<Bool>,
        workout: SavedWorkout?,
        duration: TimeInterval?,
        onShare: @escaping (String?, TimeInterval?) async -> Void,
        onSkip: @escaping () -> Void
    ) -> some View {
        modifier(ShareWorkoutPromptModifier(
            isPresented: isPresented,
            workout: workout,
            duration: duration,
            onShare: onShare,
            onSkip: onSkip
        ))
    }
}

#Preview {
    ShareWorkoutSheet(
        workout: SavedWorkout(
            name: "Push Day",
            date: Date(),
            exercises: [
                WorkoutExercise(name: "Bench Press", sets: [
                    WorkoutSet(reps: "8", weight: "100"),
                    WorkoutSet(reps: "8", weight: "100"),
                    WorkoutSet(reps: "6", weight: "100")
                ]),
                WorkoutExercise(name: "Incline Dumbbell Press", sets: [
                    WorkoutSet(reps: "10", weight: "35"),
                    WorkoutSet(reps: "10", weight: "35")
                ])
            ]
        ),
        duration: 3600,
        onShare: { _, _ in },
        onSkip: {}
    )
}
