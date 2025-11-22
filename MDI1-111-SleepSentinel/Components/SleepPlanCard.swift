//
//  SleepPlanCard.swift
//  SleepSentinel
//
//  Created by Christian Bonilla on 21/11/25.
//

import SwiftUI

struct SleepPlanCard: View {
    @EnvironmentObject var vm: SleepVM
    @State private var showBedtimePicker = false
    @State private var showWakePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Sleep Plan")
                .font(.headline)
            
            // Target bedtime + waketime
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target Bedtime:")
                    Spacer()
                    Button(format(components: vm.settings.targetBedtime)) {
                        showBedtimePicker = true
                    }
                }
                
                HStack {
                    Text("Target Wake:")
                    Spacer()
                    Button(format(components: vm.settings.targetWake)) {
                        showWakePicker = true
                    }
                }
            }
            
            // Adherence
            if let adh = vm.sleepPlanAdherence {
                Text("Adherence: \(adh * 100, specifier: "%.0f")%")
                    .foregroundColor(.secondary)
            } else {
                Text("Adherence: n/a")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .sheet(isPresented: $showBedtimePicker) {
            SleepPlanPicker(title: "Select Target Bedtime", components: $vm.settings.targetBedtime)
        }
        .sheet(isPresented: $showWakePicker) {
            SleepPlanPicker(title: "Select Target Wake", components: $vm.settings.targetWake)
        }
    }
}

func format(components: DateComponents) -> String {
    let cal = Calendar.current
    let date = cal.date(from: components) ?? Date()
    return date.formatted(date: .omitted, time: .shortened)
}
