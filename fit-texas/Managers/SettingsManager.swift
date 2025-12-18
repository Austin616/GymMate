//
//  SettingsManager.swift
//  fit-texas
//
//  Created by Claude Code on 12/18/25.
//

import SwiftUI
internal import Combine

enum WeightUnit: String, CaseIterable {
    case kg = "kg"
    case lbs = "lbs"

    var displayName: String {
        switch self {
        case .kg: return "Kilograms (kg)"
        case .lbs: return "Pounds (lbs)"
        }
    }

    // Convert from kg to this unit
    func fromKg(_ kg: Double) -> Double {
        switch self {
        case .kg: return kg
        case .lbs: return kg * 2.20462
        }
    }

    // Convert to kg from this unit
    func toKg(_ value: Double) -> Double {
        switch self {
        case .kg: return value
        case .lbs: return value / 2.20462
        }
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var weightUnit: WeightUnit {
        didSet {
            UserDefaults.standard.set(weightUnit.rawValue, forKey: "weightUnit")
        }
    }

    @Published var isDarkModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDarkModeEnabled, forKey: "isDarkModeEnabled")
        }
    }

    private init() {
        // Load weight unit preference
        if let savedUnit = UserDefaults.standard.string(forKey: "weightUnit"),
           let unit = WeightUnit(rawValue: savedUnit) {
            self.weightUnit = unit
        } else {
            self.weightUnit = .lbs // Default to lbs
        }

        // Load dark mode preference
        self.isDarkModeEnabled = UserDefaults.standard.bool(forKey: "isDarkModeEnabled")
    }

    // Format weight for display
    func formatWeight(_ weight: Double) -> String {
        return String(format: "%.1f", weight)
    }

    // Convert weight string from storage (always in kg) to display unit
    func displayWeight(_ kgString: String) -> String {
        guard let kg = Double(kgString) else { return kgString }
        let converted = weightUnit.fromKg(kg)
        return formatWeight(converted)
    }

    // Convert weight from display unit to storage (kg)
    func storageWeight(_ displayString: String) -> String {
        guard let displayValue = Double(displayString) else { return displayString }
        let kg = weightUnit.toKg(displayValue)
        return formatWeight(kg)
    }
}
