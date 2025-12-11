//
//  ContentView.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        if authManager.isAuthenticated {
            // Show main app with TabView
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                
                LogView()
                    .tabItem {
                        Label("Log", systemImage: "plus")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .accentColor(.utOrange)
            .environmentObject(authManager)
        } else {
            // Show login view
            LoginView()
                .environmentObject(authManager)
        }
    }
}

#Preview {
    ContentView()
}
