//
//  ContentView.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    @State private var selectedTab: TabItem = .home

    var body: some View {
        if authManager.isAuthenticated {
            // Show main app with custom tab bar
            CustomTabBarView(selectedTab: $selectedTab)
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
