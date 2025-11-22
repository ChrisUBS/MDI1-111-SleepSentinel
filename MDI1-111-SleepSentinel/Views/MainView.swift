// Views.swift
import SwiftUI

struct MainView: View {
    @EnvironmentObject var vm: SleepVM
    var body: some View {
        NavigationStack {
            TabView {
                TrendsView()
                    .tabItem { Label("Trends", systemImage: "chart.bar") }
                TimelineView()
                    .tabItem { Label("Timeline", systemImage: "clock") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
            .task {
                vm.motionFusion.start()
            }
        }
    }
}
