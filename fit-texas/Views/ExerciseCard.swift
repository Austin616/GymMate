import SwiftUI
import UniformTypeIdentifiers

struct ExerciseCard: View {
    @Binding var exercise: WorkoutExercise
    let exerciseIndex: Int
    let onDelete: () -> Void
    var disabled: Bool
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    @State private var draggingSet: WorkoutSet?
    
    private let cardPadding: CGFloat = 20
    private let cardCornerRadius: CGFloat = 28
    private let innerCornerRadius: CGFloat = 12
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            exerciseHeader
            setsSection
            addSetButton
        }
        .padding(cardPadding)
        .background(cardBackground)
    }
    
    // MARK: - Subviews
    private var exerciseHeader: some View {
        HStack(spacing: 12) {
            exerciseIcon
            
            Text(exercise.name)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Spacer(minLength: 8)
            
            Menu {
                Button(role: .destructive, action: handleDelete) {
                    Label("Delete Exercise", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .disabled(disabled)
        }
        .padding(.bottom, 2)
    }
    
    private var exerciseIcon: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.utOrange, Color.utOrange.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 38, height: 38)
            .overlay(
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            )
            .shadow(color: Color.utOrange.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var setsSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIdx, set in
                setRowView(setIdx: setIdx, set: set)
                    .onDrag {
                        self.draggingSet = set
                        return NSItemProvider(object: set.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: SetDropDelegate(
                        currentSet: set,
                        sets: $exercise.sets,
                        draggingSet: $draggingSet
                    ))
                if setIdx < exercise.sets.count - 1 {
                    Divider()
                        .padding(.leading, 38)
                }
            }
        }
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 0.5)
        )
    }
    
    private func setRowView(setIdx: Int, set: WorkoutSet) -> some View {
        let binding = bindingForSet(at: setIdx)
        let isDragging = draggingSet?.id == set.id
        return HStack(spacing: 12) {
            setNumberMenuBadge(setIdx: setIdx, set: set)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    // Reps
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reps")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("0", text: binding.reps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemBackground))
                            )
                            .foregroundColor(isDragging ? .secondary : .primary)
                            .disabled(disabled || binding.wrappedValue.isCompleted)
                    }
                    // Weight
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weight")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("0", text: binding.weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 80)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemBackground))
                            )
                            .foregroundColor(isDragging ? .secondary : .primary)
                            .disabled(disabled || binding.wrappedValue.isCompleted)
                    }
                    Spacer()
                    // Complete toggle button
                    Button {
                        guard !disabled else { return }
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            hapticFeedback.impactOccurred()
                            binding.wrappedValue.isCompleted.toggle()
                        }
                    } label: {
                        Image(systemName: binding.wrappedValue.isCompleted
                              ? "checkmark.circle.fill"
                              : "circle")
                        .font(.title3)
                        .foregroundColor(binding.wrappedValue.isCompleted ? .green : .secondary)
                        .padding(4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            binding.wrappedValue.isCompleted
            ? Color.green.opacity(0.12)
            : (setIdx % 2 == 0 ? Color(.systemGray6) : Color(.systemBackground))
        )
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                handleDeleteSet(at: setIdx)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .opacity(isDragging ? 0.5 : 1.0)
    }
    
    // MARK: - Badge Menu
    private func setNumberMenuBadge(setIdx: Int, set: WorkoutSet) -> some View {
        Menu {
            Button {
                setType(at: setIdx, .normal)
            } label: {
                Label("Normal Set", systemImage: "circle")
            }
            Button {
                setType(at: setIdx, .warmup)
            } label: {
                Label("Warm Up Set", systemImage: "flame")
            }
            Button {
                setType(at: setIdx, .dropset)
            } label: {
                Label("Drop Set", systemImage: "arrowtriangle.down.circle")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.utOrange.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text(badgeDescriptor(for: setIdx, set: set))
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.bold)
            }
        }
        .disabled(disabled)
    }

    private func badgeDescriptor(for idx: Int, set: WorkoutSet) -> String {
        if set.isWarmup { return "W" }
        if set.isDropSet { return "DS" }
        let workingCount = exercise.sets[0...idx].filter { !$0.isWarmup && !$0.isDropSet }.count
        return "\(workingCount)"
    }
    
    private enum SetType { case normal, warmup, dropset }
    private func setType(at idx: Int, _ type: SetType) {
        hapticFeedback.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            switch type {
            case .normal:
                exercise.sets[idx].isWarmup = false
                exercise.sets[idx].isDropSet = false
            case .warmup:
                exercise.sets[idx].isWarmup = true
                exercise.sets[idx].isDropSet = false
                moveWarmupToTop(idx)
            case .dropset:
                exercise.sets[idx].isDropSet = true
                exercise.sets[idx].isWarmup = false
            }
        }
    }
    
    private func moveWarmupToTop(_ idx: Int) {
        let set = exercise.sets.remove(at: idx)
        exercise.sets.insert(set, at: 0)
    }
    
    private func calculateDisplayNumber(for index: Int) -> String {
        let set = exercise.sets[index]
        if set.isWarmup {
            let warmupCount = exercise.sets[0...index].filter { $0.isWarmup }.count
            return "W\(warmupCount)"
        } else if set.isDropSet {
            let dropSetCount = exercise.sets[0...index].filter { $0.isDropSet }.count
            return "D\(dropSetCount)"
        } else {
            let workingCount = exercise.sets[0...index].filter { !$0.isWarmup && !$0.isDropSet }.count
            return "\(workingCount)"
        }
    }
    
    // MARK: - Bindings
    private func bindingForSet(at index: Int) -> Binding<WorkoutSet> {
        Binding<WorkoutSet>(
            get: { exercise.sets[index] },
            set: { exercise.sets[index] = $0 }
        )
    }
    
    // MARK: - Actions
    private func handleAddSet() {
        hapticFeedback.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            exercise.sets.append(
                WorkoutSet(
                    reps: "0",
                    weight: "0",
                    isCompleted: false,
                    isWarmup: false,
                    isDropSet: false
                )
            )
        }
    }

    private func handleDeleteSet(at index: Int) {
        hapticFeedback.impactOccurred(intensity: 0.7)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            exercise.sets.remove(at: index)
        }
    }
    
    private func handleDelete() {
        hapticFeedback.impactOccurred(intensity: 0.7)
        onDelete()
    }
    
    private var addSetButton: some View {
        Button(action: handleAddSet) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.headline)
                Text("Add Set")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(disabled ? Color.utOrange.opacity(0.3) : Color.utOrange)
            )
            .foregroundColor(.white)
            .shadow(
                color: disabled ? .clear : Color.utOrange.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .padding(.top, 6)
        .animation(.easeInOut(duration: 0.2), value: disabled)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius)
            .fill(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Drop Delegate for Drag & Drop Reordering (WITH TYPE BOUNDARY LOGIC)
struct SetDropDelegate: DropDelegate {
    let currentSet: WorkoutSet
    @Binding var sets: [WorkoutSet]
    @Binding var draggingSet: WorkoutSet?
    
    func performDrop(info: DropInfo) -> Bool {
        draggingSet = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggingSet = draggingSet,
              draggingSet.id != currentSet.id else { return }

        // Only allow drop inside same "type group"
        let draggingType = draggingSet.isWarmup ? "warmup" : "other"
        let currentType = currentSet.isWarmup ? "warmup" : "other"
        guard draggingType == currentType else { return }

        let from = sets.firstIndex(where: { $0.id == draggingSet.id })!
        let to = sets.firstIndex(where: { $0.id == currentSet.id })!

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            sets.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }
        func dropExited(info: DropInfo) {
            draggingSet = nil
        }
}

#Preview {
    ExerciseCard(
        exercise: .constant(
            WorkoutExercise(
                name: "Bench Press",
                sets: [
                    WorkoutSet(reps: "8", weight: "60", isCompleted: false, isWarmup: true, isDropSet: false),
                    WorkoutSet(reps: "6", weight: "80", isCompleted: true, isWarmup: false)
                ],
                notes: "Focus on form.",
            )
        ),
        exerciseIndex: 0,
        onDelete: {},
        disabled: false
    )
    .padding(.horizontal, 24)
}
