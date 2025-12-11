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
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
