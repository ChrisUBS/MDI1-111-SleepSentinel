//
//  SettingsView.swift
//  SleepSentinel
//
//  Created by Christian Bonilla on 21/11/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: SleepVM
    @State private var showShare = false
    @State private var exportURL: URL?

    var body: some View {
        Form {
            Section("Permissions") {
                Text(vm.hkAuthorized ? "HealthKit: Granted" : "HealthKit: Not granted")
            }
            Section("Demo Data") {
                Toggle("Using demo", isOn: $vm.usingDemo).disabled(true)
                Button("Load Demo Data") {
                    Task { await vm.loadDemoData() }
                }
                Toggle("Bedtime Reminders", isOn: $vm.settings.remindersEnabled)
                    .onChange(of: vm.settings.remindersEnabled) { newValue in
                        if newValue { vm.scheduleBedtimeReminder() }
                    }
            }
            Section("Sleep Plan") {
                NavigationLink("Configure Sleep Plan") {
                    VStack {
                        SleepPlanCard()
                        Spacer()
                    }
                }
            }
            Section("Export") {
                Button("Export CSV") {
                    exportURL = vm.exportCSV()
                    showShare = true
                }
            }
            Section("Privacy") {
                NavigationLink("Privacy & Data Policy") {
                    PrivacyView()
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let exportURL {
                ActivityView(activityItems: [exportURL])
                    .presentationDetents([.medium, .large])
            }
        }
    }
}
