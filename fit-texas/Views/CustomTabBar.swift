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
    case settings = 2

    var title: String {
        switch self {
        case .home: return "Home"
        case .log: return "Log"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .log: return "plus.circle.fill"
        case .settings: return "gearshape"
        }
    }

    var iconFilled: String {
        switch self {
        case .home: return "house.fill"
        case .log: return "plus.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBarView: View {
    @Binding var selectedTab: TabItem
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .log:
                    LogView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
                .edgesIgnoringSafeArea(.bottom)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @Namespace private var animation

    var body: some View {
        VStack() {
            Divider()

            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        selectedTab: $selectedTab,
                        animation: animation
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
                Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(isSelected ? .utOrange : .secondary)
                    .frame(height: 24)

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
}
