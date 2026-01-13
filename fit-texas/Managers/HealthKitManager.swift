//
//  HealthKitManager.swift
//  fit-texas
//
//  Created by Claude Code
//

import Foundation
import HealthKit
internal import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    @Published var todaySteps: Int = 0
    @Published var isAuthorized: Bool = false

    private init() {}

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        healthStore.requestAuthorization(toShare: nil, read: [stepType]) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchTodaySteps()
                }
            }
        }
    }

    func fetchTodaySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    self.todaySteps = 0
                }
                return
            }

            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self.todaySteps = steps
            }
        }

        healthStore.execute(query)
    }

    func startObservingSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                self?.fetchTodaySteps()
            }
        }

        healthStore.execute(query)
    }
    
    // MARK: - Historical Data
    
    /// Fetch steps for a specific date
    func fetchSteps(for date: Date, completion: @escaping (Int) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                completion(steps)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch steps for a date range
    func fetchSteps(from startDate: Date, to endDate: Date, completion: @escaping ([Date: Int]) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion([:])
            return
        }
        
        let calendar = Calendar.current
        let anchorDate = calendar.startOfDay(for: startDate)
        let interval = DateComponents(day: 1)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, results, error in
            guard let results = results else {
                DispatchQueue.main.async {
                    completion([:])
                }
                return
            }
            
            var stepsByDate: [Date: Int] = [:]
            
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                let date = calendar.startOfDay(for: statistics.startDate)
                let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                stepsByDate[date] = Int(steps)
            }
            
            DispatchQueue.main.async {
                completion(stepsByDate)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Hourly Data
    
    /// Fetch hourly steps for a specific date
    func fetchHourlySteps(for date: Date, completion: @escaping ([HourlySteps]) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            completion([])
            return
        }
        
        let anchorDate = startOfDay
        let interval = DateComponents(hour: 1)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, results, error in
            guard let results = results else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            var hourlySteps: [HourlySteps] = []
            let now = Date()
            
            results.enumerateStatistics(from: startOfDay, to: min(endOfDay, now)) { statistics, _ in
                let hour = calendar.component(.hour, from: statistics.startDate)
                let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                
                hourlySteps.append(HourlySteps(
                    hour: hour,
                    steps: Int(steps),
                    date: statistics.startDate
                ))
            }
            
            DispatchQueue.main.async {
                completion(hourlySteps)
            }
        }
        
        healthStore.execute(query)
    }
}

// MARK: - Supporting Models

struct HourlySteps: Identifiable {
    let id = UUID()
    let hour: Int
    let steps: Int
    let date: Date
    
    var hourLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased()
    }
    
    var shortLabel: String {
        if hour == 0 {
            return "12a"
        } else if hour < 12 {
            return "\(hour)a"
        } else if hour == 12 {
            return "12p"
        } else {
            return "\(hour - 12)p"
        }
    }
}
