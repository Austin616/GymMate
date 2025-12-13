//
//  WorkoutTimerManager.swift
//  fit-texas
//
//  Created by Claude Code on 12/13/25.
//

import Foundation
import SwiftUI
import UserNotifications
import ActivityKit
internal import Combine

class WorkoutTimerManager: NSObject, ObservableObject {
    static let shared = WorkoutTimerManager()

    @Published var isWorkoutActive: Bool = false
    @Published var workoutStartTime: Date?
    @Published var elapsedTime: TimeInterval = 0

    private var timer: Timer?
    private var activity: Any? // Activity<WorkoutActivityAttributes> but we store as Any for iOS <16.1 compatibility
    private let notificationIdentifier = "active-workout-timer"

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // Call this after the view hierarchy is set up
    func initialize() {
        loadPersistedState()
        requestNotificationPermissions()
    }

    // MARK: - Timer Control

    func startWorkout(startTime: Date) {
        workoutStartTime = startTime
        isWorkoutActive = true
        persistState()

        startForegroundTimer()
        scheduleNotifications()
    }

    func stopWorkout() {
        isWorkoutActive = false
        workoutStartTime = nil
        elapsedTime = 0

        stopForegroundTimer()
        cancelNotifications()
        clearPersistedState()
    }

    // MARK: - Foreground Timer

    private func startForegroundTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopForegroundTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsedTime() {
        guard let startTime = workoutStartTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
    }

    // MARK: - Notifications

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            }
        }
    }

    private func scheduleNotifications() {
        if #available(iOS 16.1, *) {
            startLiveActivity()
        } else {
            // Fallback for older iOS versions - use regular notifications
            scheduleFallbackNotification()
        }
    }

    @available(iOS 16.1, *)
    private func startLiveActivity() {
        guard let startTime = workoutStartTime else { return }

        // End any existing activity first
        endLiveActivity()

        let attributes = WorkoutActivityAttributes(workoutName: "Workout in Progress")
        let contentState = WorkoutActivityAttributes.ContentState(
            startTime: startTime,
            exerciseCount: 0,
            completedSets: 0,
            totalSets: 0
        )

        do {
            let newActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            activity = newActivity
            print("✅ Live Activity started")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }

    @available(iOS 16.1, *)
    func updateLiveActivity(exerciseCount: Int, completedSets: Int, totalSets: Int) {
        guard let startTime = workoutStartTime,
              let activity = activity as? Activity<WorkoutActivityAttributes> else {
            return
        }

        let contentState = WorkoutActivityAttributes.ContentState(
            startTime: startTime,
            exerciseCount: exerciseCount,
            completedSets: completedSets,
            totalSets: totalSets
        )

        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }

    @available(iOS 16.1, *)
    private func endLiveActivity() {
        guard let activity = activity as? Activity<WorkoutActivityAttributes> else { return }

        Task {
            // End immediately with no final content - removes it right away
            await activity.end(nil, dismissalPolicy: .immediate)
            print("✅ Live Activity ended immediately")
        }

        self.activity = nil
    }

    private func scheduleFallbackNotification() {
        guard let startTime = workoutStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60

        let timeString: String
        if hours > 0 {
            timeString = String(format: "%d:%02d", hours, minutes)
        } else {
            timeString = String(format: "%d min", minutes)
        }

        let content = UNMutableNotificationContent()
        content.title = "Workout in Progress"
        content.body = "Time: \(timeString)"
        content.sound = nil
        content.badge = nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error)")
            }
        }
    }

    private func cancelNotifications() {
        if #available(iOS 16.1, *) {
            endLiveActivity()
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
        }
    }

    // MARK: - State Persistence

    private let startTimeKey = "workout_start_time"
    private let isActiveKey = "workout_is_active"

    private func persistState() {
        UserDefaults.standard.set(workoutStartTime, forKey: startTimeKey)
        UserDefaults.standard.set(isWorkoutActive, forKey: isActiveKey)
    }

    private func loadPersistedState() {
        guard let startTime = UserDefaults.standard.object(forKey: startTimeKey) as? Date,
              UserDefaults.standard.bool(forKey: isActiveKey) else {
            return
        }

        workoutStartTime = startTime
        isWorkoutActive = true
        updateElapsedTime() // Update elapsed time immediately
        startForegroundTimer()

        print("✅ Restored workout timer from \(startTime)")
    }

    private func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: startTimeKey)
        UserDefaults.standard.removeObject(forKey: isActiveKey)
    }

    // MARK: - App Lifecycle Handlers

    func handleAppDidEnterBackground() {
        // Notifications are already scheduled
        // Just ensure they're active
        if isWorkoutActive {
            scheduleNotifications()
        }
    }

    func handleAppWillEnterForeground() {
        // Cancel notifications when app returns
        cancelNotifications()

        // Restart foreground timer
        if isWorkoutActive {
            startForegroundTimer()
            updateElapsedTime()
        }
    }

    // MARK: - Helper Methods

    func formattedElapsedTime() -> String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
