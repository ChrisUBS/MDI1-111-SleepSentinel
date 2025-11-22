//
//  MDI1_111_SleepSentinelApp.swift
//  MDI1-111-SleepSentinel
//
//  Created by Christian Bonilla on 21/11/25.
//

import SwiftUI

@main
struct MDI1_111_SleepSentinelApp: App {
    @StateObject private var vm = SleepVM()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if vm.hkAuthorized {
                    MainView()
                        .environmentObject(vm)
                        .task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            if vm.nights.isEmpty {
                                await vm.loadDemoData()
                            }
                            vm.loadCache()
                        }
                } else {
                    OnboardingView()
                        .environmentObject(vm)
                }
            }
        }
    }
}
