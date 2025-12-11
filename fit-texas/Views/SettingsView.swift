//
//  Settings.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Settings")
                .font(.largeTitle)
                .bold()
            
            Button(action: {
                authManager.signOut()
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                    Text("Sign Out")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.utOrange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}

#Preview {
    SettingsView().environmentObject(AuthManager())
}
