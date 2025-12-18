//
//  fit_texasApp.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI
import FirebaseCore

@main
struct fit_texasApp: App {
    @StateObject private var timerManager = WorkoutTimerManager.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
                .preferredColorScheme(settingsManager.isDarkModeEnabled ? .dark : .light)
                .onAppear {
                    timerManager.initialize()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch newPhase {
                    case .background:
                        timerManager.handleAppDidEnterBackground()
                    case .active:
                        timerManager.handleAppWillEnterForeground()
                    default:
                        break
                    }
                }
        }
    }
}
