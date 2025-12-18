//
//  Settings.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var settingsManager = SettingsManager.shared
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            CustomTabHeader(
                title: "Settings",
                leadingButton: AnyView(
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body)
                                .fontWeight(.semibold)
                            Text("Back")
                        }
                        .foregroundColor(.utOrange)
                    }
                ),
                isSubScreen: true
            )

            List {
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $settingsManager.isDarkModeEnabled) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.utOrange)
                            Text("Dark Mode")
                        }
                    }
                    .tint(.utOrange)
                }

                Section(header: Text("Units")) {
                    Picker("Weight Unit", selection: $settingsManager.weightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Button(action: {
                        authManager.signOut()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SettingsView().environmentObject(AuthManager())
}
