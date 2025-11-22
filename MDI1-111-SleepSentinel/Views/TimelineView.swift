//
//  TimelineView.swift
//  SleepSentinel
//
//  Created by Christian Bonilla on 21/11/25.
//

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var vm: SleepVM
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    var body: some View {
        Group {
            if vm.nights.isEmpty {
                ContentUnavailableView("No sleep data",
                                       systemImage: "clock",
                                       description: Text("Grant Health Access or use Demo Mode to see your nightly timeline."))
            } else {
                let maxDuration = vm.nights.compactMap { $0.inBed }.max() ?? 1
                
                if let onset = vm.inferredOnset {
                    Text("Inferred Onset: \(onset.formatted(date: .omitted, time: .shortened))")
                        .foregroundColor(.blue)
                }

                if let wake = vm.inferredWake {
                    Text("Inferred Wake: \(wake.formatted(date: .omitted, time: .shortened))")
                        .foregroundColor(.orange)
                }
                
                List(vm.nights) { night in
                    VStack(alignment: .leading, spacing: 8) {
                        
                        // DATE
                        Text(dateFormatter.string(from: night.date))
                            .font(.headline)
                        
                        // BARS
                        ZStack(alignment: .leading) {
                            
                            // In-bed bar (background)
                            if let inBed = night.inBed {
                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.25))
                                    .frame(
                                        width: barWidth(for: inBed, maxDuration: maxDuration),
                                        height: 16
                                    )
                                    .cornerRadius(6)
                            }
                            
                            // Asleep bar (foreground)
                            if let asleep = night.asleep {
                                Rectangle()
                                    .foregroundColor(.blue.opacity(0.7))
                                    .frame(
                                        width: barWidth(for: asleep, maxDuration: maxDuration),
                                        height: 16
                                    )
                                    .cornerRadius(6)
                            }
                        }
                        
                        // TEXT METRICS
                        VStack(alignment: .leading, spacing: 2) {
                            if let asleep = night.asleep {
                                Text("Asleep: \(asleep/3600, specifier: "%.2f") hrs")
                                    .font(.subheadline)
                            }
                            if let eff = night.efficiency {
                                Text("Efficiency: \(eff*100, specifier: "%.0f")%")
                                    .font(.footnote)
                                    .foregroundColor(eff > 0.85 ? .green : .orange)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Timeline")
    }
    
    // Normalizes bar widths to the screen
    private func barWidth(for duration: TimeInterval, maxDuration: TimeInterval) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 40
        let normalized = duration / maxDuration
        return max(8, screenWidth * normalized)
    }
}
