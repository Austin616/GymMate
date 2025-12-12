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
        NavigationView {
            VStack(spacing: 0) {
                CustomTabHeader(title: "Home")

                VStack {
                    Text("Hello \(authManager.currentUser?.displayName ?? "Anonymous")!")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    HomeView().environmentObject(AuthManager())
}
