//
//  HomeView.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Text("Hello \(authManager.currentUser?.displayName ?? "Anonymous")!")
    }
}

#Preview {
    HomeView().environmentObject(AuthManager())
}
