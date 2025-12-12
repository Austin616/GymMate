//
//  ProfileView.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var historyManager = WorkoutHistoryManager()
    @StateObject private var statsManager = StatsManager()
    @State private var showSettings = false
    @State private var selectedDate = Date()
    @State private var statsLoaded = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CustomTabHeader(
                    title: "Profile",
                    trailingButton: AnyView(
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.utOrange)
                                .font(.title3)
                        }
                    )
                )

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 12) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.utOrange, Color.utOrange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text((authManager.currentUser?.email?.prefix(1).uppercased()) ?? "U")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color.utOrange.opacity(0.3), radius: 12, x: 0, y: 4)

                            VStack(spacing: 4) {
                                Text(authManager.currentUser?.displayName ?? "User")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text(authManager.currentUser?.email ?? "user@example.com")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)

                    // Calendar Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Calendar")
                            .font(.headline)
                            .padding(.horizontal)

                        CalendarView(selectedDate: $selectedDate)
                            .padding(.horizontal, 8)
                    }

                    // Stats Cards
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stats")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                StatCardProfile(title: "Workouts", value: "\(statsManager.stats.totalWorkouts)", icon: "figure.strengthtraining.traditional")
                                StatCardProfile(title: "Streak", value: "\(statsManager.stats.currentStreak)", icon: "flame.fill")
                            }

                            HStack(spacing: 12) {
                                StatCardProfile(title: "Volume", value: "\(statsManager.formattedVolume()) kg", icon: "scalemass.fill")
                                StatCardProfile(title: "This Week", value: "\(statsManager.stats.workoutsThisWeek)", icon: "calendar")
                            }
                        }
                        .padding(.horizontal)
                    }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsSheet()
                    .environmentObject(authManager)
            }
            .onAppear {
                if !statsLoaded {
                    print("📊 [PROFILE] Loading stats...")
                    statsManager.calculateStats(from: historyManager.savedWorkouts)
                    statsLoaded = true
                }
            }
            .onChange(of: historyManager.savedWorkouts) { newWorkouts in
                print("📊 [PROFILE] Workouts changed, recalculating stats...")
                statsManager.calculateStats(from: newWorkouts)
            }
        }
    }
}

struct StatCardProfile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.utOrange)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var dates: [Date] = []
        var date = monthFirstWeek.start

        while date < monthInterval.end {
            dates.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }

        return dates
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month/Year Header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.utOrange)
                }

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.utOrange)
                }
            }
            .padding(.horizontal)

            // Days of Week
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        selectedDate: $selectedDate,
                        currentMonth: currentMonth
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    private func previousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = newMonth
    }

    private func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = newMonth
    }
}

struct CalendarDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let currentMonth: Date

    private let calendar = Calendar.current

    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    var body: some View {
        Button(action: {
            selectedDate = date
        }) {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(
                    isSelected ? .white :
                    isToday ? .utOrange :
                    isInCurrentMonth ? .primary : .secondary
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.utOrange : Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(isToday && !isSelected ? Color.utOrange : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .opacity(isInCurrentMonth ? 1.0 : 0.4)
    }
}

struct SettingsSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CustomTabHeader(
                    title: "Settings",
                    trailingButton: AnyView(
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.utOrange)
                        .fontWeight(.semibold)
                    ),
                    isSubScreen: true
                )

                List {
                    Section {
                        Button(action: {
                            authManager.signOut()
                            dismiss()
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
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
