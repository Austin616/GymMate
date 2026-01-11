//
//  ExerciseDetailView.swift
//  fit-texas
//
//  Created by Claude Code on 12/18/25.
//

import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var currentImageIndex = 0
    @State private var timer: Timer?

    private func loadExerciseImage(at index: Int) -> UIImage? {
        guard let images = exercise.images, index < images.count else {
            return nil
        }

        let imagePath = images[index]

        // Try multiple paths to locate the image in the bundle
        // Path 1: exercises/3_4_Sit-Up/0.jpg (full path with extension)
        if let path = Bundle.main.path(forResource: "exercises/\(imagePath)", ofType: nil),
           let image = UIImage(contentsOfFile: path) {
            return image
        }

        // Path 2: Using inDirectory parameter
        if let path = Bundle.main.path(forResource: imagePath, ofType: nil, inDirectory: "exercises"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }

        // Path 3: Construct absolute path from bundle
        let path = Bundle.main.bundlePath + "/exercises/\(imagePath)"
        if let image = UIImage(contentsOfFile: path) {
            return image
        }

        return nil
    }

    private func startImageTimer() {
        guard let images = exercise.images, images.count > 1 else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentImageIndex = (currentImageIndex + 1) % images.count
            }
        }
    }

    private func stopImageTimer() {
        timer?.invalidate()
        timer = nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Close Button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }

                // Hero Image with alternation
                if let uiImage = loadExerciseImage(at: currentImageIndex) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(20)
                            .transition(.opacity)

                        // Image indicator dots
                        if let images = exercise.images, images.count > 1 {
                            HStack(spacing: 6) {
                                ForEach(0..<images.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentImageIndex ? Color.utOrange : Color.white.opacity(0.5))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .padding(12)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Fallback icon if no image
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.utOrange.opacity(0.2), Color.utOrange.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 200)

                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 80))
                            .foregroundColor(.utOrange)
                    }
                    .padding(.horizontal)
                }

                    VStack(alignment: .leading, spacing: 20) {
                        // Exercise Name
                        Text(exercise.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        // Info Tags
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                if let level = exercise.level {
                                    InfoTag(icon: "chart.bar.fill", text: level, color: .blue)
                                }
                                if let equipment = exercise.equipment {
                                    InfoTag(icon: "dumbbell.fill", text: equipment, color: .green)
                                }
                                if let category = exercise.category {
                                    InfoTag(icon: "tag.fill", text: category, color: .purple)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Primary Muscles
                        if let primaryMuscles = exercise.primaryMuscles, !primaryMuscles.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Primary Muscles", systemImage: "figure.arms.open")
                                    .font(.headline)
                                    .foregroundColor(.utOrange)

                                FlowLayout(spacing: 8) {
                                    ForEach(primaryMuscles, id: \.self) { muscle in
                                        MuscleTag(muscle: muscle, isPrimary: true)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Secondary Muscles
                        if let secondaryMuscles = exercise.secondaryMuscles, !secondaryMuscles.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Secondary Muscles", systemImage: "figure.stand")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                FlowLayout(spacing: 8) {
                                    ForEach(secondaryMuscles, id: \.self) { muscle in
                                        MuscleTag(muscle: muscle, isPrimary: false)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Instructions
                        if let instructions = exercise.instructions, !instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Instructions", systemImage: "list.number")
                                    .font(.headline)
                                    .foregroundColor(.utOrange)

                                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                                    HStack(alignment: .top, spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.utOrange.opacity(0.15))
                                                .frame(width: 28, height: 28)
                                            Text("\(index + 1)")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.utOrange)
                                        }

                                        Text(instruction)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        .overlay(alignment: .bottom) {
            // Add Button - Smaller and more subtle
            Button(action: {
                onAdd()
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                    Text("Add to Workout")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.utOrange)
                        .shadow(color: Color.utOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .onAppear {
            startImageTimer()
        }
        .onDisappear {
            stopImageTimer()
        }
    }
}

// MARK: - Supporting Views

struct InfoTag: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

struct MuscleTag: View {
    let muscle: String
    let isPrimary: Bool

    var body: some View {
        Text(muscle.capitalized)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isPrimary ? Color.utOrange.opacity(0.15) : Color(.systemGray5))
            .foregroundColor(isPrimary ? .utOrange : .secondary)
            .cornerRadius(8)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    ExerciseDetailView(
        exercise: Exercise(
            id: "1",
            name: "Barbell Bench Press",
            force: "Push",
            level: "Intermediate",
            mechanic: "Compound",
            equipment: "Barbell",
            primaryMuscles: ["chest", "triceps"],
            secondaryMuscles: ["shoulders"],
            instructions: [
                "Lie flat on a bench with your feet on the floor",
                "Grip the bar slightly wider than shoulder-width",
                "Lower the bar to your chest with control",
                "Press the bar back up to starting position"
            ],
            category: "Strength",
            images: nil
        ),
        onAdd: { print("Added") }
    )
}
