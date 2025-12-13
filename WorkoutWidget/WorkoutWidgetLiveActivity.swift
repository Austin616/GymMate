//
//  WorkoutWidgetLiveActivity.swift
//  WorkoutWidget
//
//  Live Activity for workout timer
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct WorkoutWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock screen/banner UI
            WorkoutLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.2))
                .activitySystemActionForegroundColor(Color.orange)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.orange)
                        .font(.title2)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(context.state.startTime, style: .timer)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .monospacedDigit()

                        if context.state.exerciseCount > 0 {
                            Text("\(context.state.completedSets)/\(context.state.totalSets) sets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout in Progress")
                            .font(.headline)

                        if context.state.exerciseCount > 0 {
                            Text("\(context.state.exerciseCount) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Spacer()

                        // Progress bar
                        if context.state.totalSets > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Progress")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                ProgressView(value: Double(context.state.completedSets), total: Double(context.state.totalSets))
                                    .tint(.orange)
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.orange)
                    .monospacedDigit()
                    .frame(width: 50)
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.orange)
            }
            .keylineTint(.orange)
        }
    }
}

// MARK: - Live Activity View

@available(iOS 16.1, *)
struct WorkoutLiveActivityView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("Workout in Progress")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    // Timer with auto-updating style
                    Text(context.state.startTime, style: .timer)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.orange)
                        .monospacedDigit()

                    if context.state.exerciseCount > 0 {
                        Text("•")
                            .foregroundColor(.secondary)

                        Text("\(context.state.exerciseCount) exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text("\(context.state.completedSets)/\(context.state.totalSets) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Progress indicator
            if context.state.totalSets > 0 {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 36, height: 36)

                    Circle()
                        .trim(from: 0, to: CGFloat(context.state.completedSets) / CGFloat(context.state.totalSets))
                        .stroke(Color.orange, lineWidth: 3)
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int((Double(context.state.completedSets) / Double(context.state.totalSets)) * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(12)
    }
}

@available(iOS 16.1, *)
#Preview("Notification", as: .content, using: WorkoutActivityAttributes(workoutName: "Workout")) {
   WorkoutWidgetLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(startTime: Date(), exerciseCount: 3, completedSets: 8, totalSets: 12)
    WorkoutActivityAttributes.ContentState(startTime: Date().addingTimeInterval(-300), exerciseCount: 5, completedSets: 15, totalSets: 20)
}
