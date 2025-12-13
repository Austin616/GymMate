//
//  WorkoutActivityAttributes.swift
//  fit-texas
//
//  Shared between app and widget
//

import Foundation
import ActivityKit

@available(iOS 16.1, *)
public struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var startTime: Date
        public var exerciseCount: Int
        public var completedSets: Int
        public var totalSets: Int

        public init(startTime: Date, exerciseCount: Int, completedSets: Int, totalSets: Int) {
            self.startTime = startTime
            self.exerciseCount = exerciseCount
            self.completedSets = completedSets
            self.totalSets = totalSets
        }
    }

    public var workoutName: String

    public init(workoutName: String) {
        self.workoutName = workoutName
    }
}
