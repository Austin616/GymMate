//
//  SetRow.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI

struct SetRow: View {
    @Binding var set: WorkoutSet
    let setIndex: Int
    let onDelete: () -> Void
    var disabled: Bool

    @FocusState private var focusedField: Field?

    enum Field {
        case weight, reps, rpe
    }

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                if set.isWarmup {
                    Circle()
                        .fill(Color.utOrange.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Text("W")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.utOrange)
                } else {
                    Text("\(setIndex + 1)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 40)

            Text("-")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 65)

            TextField("0", text: $set.weight)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 58)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.systemGray6))
                )
                .focused($focusedField, equals: .weight)
                .disabled(disabled)

            TextField("0", text: $set.reps)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 58)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.systemGray6))
                )
                .focused($focusedField, equals: .reps)
                .disabled(disabled)

            TextField("0", text: $set.rpe)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 48)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.systemGray6))
                )
                .focused($focusedField, equals: .rpe)
                .disabled(disabled)

            Button(action: { set.isCompleted.toggle() }) {
                ZStack {
                    if set.isCompleted {
                        Circle()
                            .fill(Color.utOrange)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .strokeBorder(Color(.systemGray4), lineWidth: 2)
                            .frame(width: 22, height: 22)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(disabled)

            Spacer(minLength: 0)

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            set.isCompleted ?
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.utOrange.opacity(0.08)) : RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.clear)
        )
    }
}


