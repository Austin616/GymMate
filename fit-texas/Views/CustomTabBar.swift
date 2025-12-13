//
//  CustomTabBar.swift
//  fit-texas
//
//  Created by Austin Tran on 12/11/25.
//

import SwiftUI

enum TabItem: Int, CaseIterable {
    case home = 0
    case log = 1
    case profile = 2

    var title: String {
        switch self {
        case .home: return "Home"
        case .log: return "Log"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .log: return "plus.circle.fill"
        case .profile: return "person"
        }
    }

    var iconFilled: String {
        switch self {
        case .home: return "house.fill"
        case .log: return "plus.circle.fill"
        case .profile: return "person.fill"
        }
    }
}

struct CustomTabBarView: View {
    @Binding var selectedTab: TabItem
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var timerManager: WorkoutTimerManager
    @StateObject private var historyManager = WorkoutHistoryManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .log:
                    WorkoutsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(historyManager)

            VStack(spacing: 0) {
                Spacer()

                // Workout Preview Card
                if historyManager.hasDraft {
                    ActiveWorkoutPreview(
                        historyManager: historyManager,
                        timerManager: timerManager,
                        onTap: {
                            withAnimation {
                                selectedTab = .log
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.identity) // No animation - disappears instantly
                }

                // Custom Tab Bar
                CustomTabBar(
                    selectedTab: $selectedTab,
                    hasActiveWorkout: historyManager.hasDraft
                )
                .edgesIgnoringSafeArea(.bottom)
            }
            .animation(.none, value: historyManager.hasDraft) // Disable animation for preview show/hide
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    let hasActiveWorkout: Bool
    @Namespace private var animation

    var body: some View {
        VStack() {
            Divider()

            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        selectedTab: $selectedTab,
                        animation: animation,
                        hasActiveWorkout: hasActiveWorkout
                    )
                }
            }
            .padding(.top, 8)
            .background(Color(.systemBackground))
        }
    }
}

struct TabBarButton: View {
    let tab: TabItem
    @Binding var selectedTab: TabItem
    var animation: Namespace.ID
    let hasActiveWorkout: Bool

    private var isSelected: Bool {
        selectedTab == tab
    }

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(isSelected ? .utOrange : .secondary)
                        .frame(height: 24)

                    if tab == .log && hasActiveWorkout {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: 8, y: -8)
                    }
                }

                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .utOrange : .secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CustomTabBarView(selectedTab: .constant(.home))
        .environmentObject(AuthManager())
        .environmentObject(WorkoutTimerManager.shared)
}
