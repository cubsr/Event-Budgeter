//
//  TabNavigationState.swift
//  Event Budgeter
//

import Combine
import SwiftUI

final class TabNavigationState: ObservableObject {
    @Published var selectedTab: AppTab = .events
    @Published var resetCounters: [AppTab: Int] = Dictionary(
        uniqueKeysWithValues: AppTab.allCases.map { ($0, 0) }
    )

    func selectOrReset(_ tab: AppTab) {
        if selectedTab == tab {
            resetCounters[tab, default: 0] += 1
        } else {
            selectedTab = tab
        }
    }
}
