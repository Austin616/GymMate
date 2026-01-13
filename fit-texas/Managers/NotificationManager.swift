//
//  NotificationManager.swift
//  fit-texas
//
//  Created by GymMate
//

import Foundation
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
internal import Combine

// Note: FirebaseMessaging is optional - add to project if push notifications are needed
// import FirebaseMessaging

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var fcmToken: String?
    @Published var unreadNotificationCount: Int = 0
    @Published var pendingFriendRequestCount: Int = 0
    
    private let db = Firestore.firestore()
    
    private override init() {
        super.init()
        print("🔵 [NOTIFICATIONS] Initializing NotificationManager...")
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        // Note: To enable FCM, uncomment FirebaseMessaging import and add:
        // Messaging.messaging().delegate = self
    }
    
    // MARK: - Permission Request
    
    func requestAuthorization() async -> Bool {
        print("🔵 [NOTIFICATIONS] Requesting notification authorization...")
        
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                print("✅ [NOTIFICATIONS] Already authorized")
                await registerForRemoteNotifications()
                return true
                
            case .notDetermined:
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                )
                
                if granted {
                    print("✅ [NOTIFICATIONS] Authorization granted")
                    await registerForRemoteNotifications()
                } else {
                    print("⚠️ [NOTIFICATIONS] Authorization denied")
                }
                return granted
                
            case .denied:
                print("❌ [NOTIFICATIONS] Authorization denied")
                return false
                
            @unknown default:
                return false
            }
        } catch {
            print("❌ [NOTIFICATIONS] Authorization error: \(error)")
            return false
        }
    }
    
    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Token Management
    
    func saveFCMToken(_ token: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("🔵 [NOTIFICATIONS] Saving FCM token...")
        
        do {
            try await db.collection("users").document(userId)
                .collection("profile").document("data")
                .updateData(["fcmToken": token])
            
            DispatchQueue.main.async {
                self.fcmToken = token
            }
            
            print("✅ [NOTIFICATIONS] FCM token saved")
        } catch {
            print("❌ [NOTIFICATIONS] Error saving FCM token: \(error)")
        }
    }
    
    func removeFCMToken() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await db.collection("users").document(userId)
                .collection("profile").document("data")
                .updateData(["fcmToken": FieldValue.delete()])
            
            print("✅ [NOTIFICATIONS] FCM token removed")
        } catch {
            print("❌ [NOTIFICATIONS] Error removing FCM token: \(error)")
        }
    }
    
    // MARK: - Local Notifications
    
    func scheduleLocalNotification(
        title: String,
        body: String,
        identifier: String,
        delay: TimeInterval = 0
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger: UNNotificationTrigger?
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = nil
        }
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [NOTIFICATIONS] Error scheduling notification: \(error)")
            } else {
                print("✅ [NOTIFICATIONS] Notification scheduled: \(identifier)")
            }
        }
    }
    
    // MARK: - Achievement Notification
    
    func notifyAchievementUnlocked(_ achievement: Achievement) {
        scheduleLocalNotification(
            title: "🏆 Achievement Unlocked!",
            body: "\(achievement.name) - \(achievement.description)",
            identifier: "achievement_\(achievement.id)"
        )
    }
    
    // MARK: - Level Up Notification
    
    func notifyLevelUp(newLevel: Int) {
        let title = LevelSystem.levelTitle(for: newLevel)
        scheduleLocalNotification(
            title: "🎉 Level Up!",
            body: "You've reached Level \(newLevel) - \(title)!",
            identifier: "level_up_\(newLevel)"
        )
    }
    
    // MARK: - Challenge Notification
    
    func notifyChallengeCompleted(_ challenge: Challenge) {
        scheduleLocalNotification(
            title: "✅ Challenge Complete!",
            body: "You completed: \(challenge.title) (+\(challenge.xpReward) XP)",
            identifier: "challenge_\(challenge.id)"
        )
    }
    
    func notifyNewChallenge(_ challenge: Challenge) {
        scheduleLocalNotification(
            title: "🎯 New Challenge Available!",
            body: "\(challenge.title) - \(challenge.description)",
            identifier: "new_challenge_\(challenge.id)"
        )
    }
    
    // MARK: - Friend Request Notification
    
    func notifyFriendRequest(from username: String) {
        scheduleLocalNotification(
            title: "👋 Friend Request",
            body: "\(username) wants to be your friend!",
            identifier: "friend_request_\(UUID().uuidString)"
        )
        
        DispatchQueue.main.async {
            self.pendingFriendRequestCount += 1
        }
    }
    
    func notifyFriendRequestAccepted(by username: String) {
        scheduleLocalNotification(
            title: "🤝 Friend Added!",
            body: "\(username) accepted your friend request",
            identifier: "friend_accepted_\(UUID().uuidString)"
        )
    }
    
    // MARK: - Social Notifications
    
    func notifyPostLiked(by username: String, postName: String) {
        scheduleLocalNotification(
            title: "❤️ New Like",
            body: "\(username) liked your \(postName) workout",
            identifier: "like_\(UUID().uuidString)"
        )
    }
    
    func notifyPostCommented(by username: String, postName: String) {
        scheduleLocalNotification(
            title: "💬 New Comment",
            body: "\(username) commented on your \(postName) workout",
            identifier: "comment_\(UUID().uuidString)"
        )
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().setBadgeCount(count)
            self.unreadNotificationCount = count
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    func updatePendingRequestCount(_ count: Int) {
        DispatchQueue.main.async {
            self.pendingFriendRequestCount = count
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        print("🔵 [NOTIFICATIONS] User tapped notification: \(identifier)")
        
        // Handle notification tap based on identifier
        // This could navigate to specific screens
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate (Enable when FirebaseMessaging is added)
// To enable FCM push notifications:
// 1. Add FirebaseMessaging to your project dependencies
// 2. Uncomment the import statement at the top
// 3. Uncomment this extension

/*
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        print("🔵 [NOTIFICATIONS] Received FCM token: \(token.prefix(20))...")
        
        Task {
            await saveFCMToken(token)
        }
    }
}
*/

// MARK: - Notification Types

enum NotificationType: String {
    case friendRequest = "friend_request"
    case friendAccepted = "friend_accepted"
    case postLiked = "post_liked"
    case postCommented = "post_commented"
    case achievementUnlocked = "achievement_unlocked"
    case challengeCompleted = "challenge_completed"
    case newChallenge = "new_challenge"
    case levelUp = "level_up"
}
