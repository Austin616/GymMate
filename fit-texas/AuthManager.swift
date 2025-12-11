//
//  AuthManager.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI
import FirebaseAuth
internal import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    private var listenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        self.currentUser = Auth.auth().currentUser
        self.isAuthenticated = currentUser != nil

        // Save the handle so you can remove the listener later
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }

    deinit {
        // Clean up the listener when manager is destroyed
        if let listenerHandle = listenerHandle {
            Auth.auth().removeStateDidChangeListener(listenerHandle)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
