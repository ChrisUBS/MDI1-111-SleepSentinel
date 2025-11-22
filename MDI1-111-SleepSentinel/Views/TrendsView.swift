import SwiftUI

struct TrendsView: View {
    @EnvironmentObject var vm: SleepVM
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        return df
    }()
    
    var body: some View {
        Group {
            if vm.nights.isEmpty {
                ContentUnavailableView(
                    "No sleep data",
                    systemImage: "zzz",
                    description: Text("Grant Health Access or use Demo Mode to see trends.")
                )
            } else {

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 24) {

                        // MARK: - Chart
                        SleepTrendsChart()
                            .environmentObject(vm)
                            .frame(height: 280)
                            .padding(.top, 8)

                        // MARK: - Chronotype
                        ChronotypeCard()
                            .environmentObject(vm)
                        
                        if let onset = vm.inferredOnset {
                            Text("Inferred Sleep Onset: \(onset.formatted(date: .omitted, time: .shortened))")
                                .foregroundColor(.secondary)
                        }

                        if let wake = vm.inferredWake {
                            Text("Inferred Wake: \(wake.formatted(date: .omitted, time: .shortened))")
                                .foregroundColor(.secondary)
                        }

                        // MARK: - Summary
                        ConsistencySummaryCard()
                            .environmentObject(vm)

                        // MARK: - Nights List (no List, just VStack)
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(vm.nights) { night in
                                VStack(alignment: .leading, spacing: 6) {
                                    
                                    Text(dateFormatter.string(from: night.date))
                                        .font(.headline)
                                    
                                    if let asleep = night.asleep {
                                        Text("Asleep: \(asleep / 3600, specifier: "%.2f") hours")
                                    }
                                    
                                    if let eff = night.efficiency {
                                        Text("Efficiency: \(eff * 100, specifier: "%.0f")%")
                                            .foregroundColor(eff > 0.85 ? .green : .orange)
                                    }
                                    
                                    if let mid = night.midpoint {
                                        Text("Midpoint: \(timeFormatter.string(from: mid))")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(14)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .navigationTitle("Trends")
    }
}
