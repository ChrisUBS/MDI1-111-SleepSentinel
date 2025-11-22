//
//  SleepTrendsChart.swift
//  SleepSentinel
//
//  Created by Christian Bonilla on 21/11/25.
//

import SwiftUI
import Charts

struct SleepTrendsChart: View {
    @EnvironmentObject var vm: SleepVM
    
    var body: some View {
        Chart {
            ForEach(vm.nights) { night in
                
                // BAR: asleep duration in hours
                if let asleep = night.asleep {
                    BarMark(
                        x: .value("Date", night.date),
                        y: .value("Hours Asleep", asleep / 3600)
                    )
                    .foregroundStyle(.blue.opacity(0.6))
                }
                
                // POINT: midpoint as a time-of-day value
                if let mid = night.midpoint {
                    PointMark(
                        x: .value("Date", night.date),
                        y: .value("Midpoint (hrs)", midpointAsHours(mid))
                    )
                    .foregroundStyle(.orange)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .frame(height: 220)
        .padding()
    }
    
    // Converts a midpoint date → hour-of-day like 2.5 = 2:30 AM
    func midpointAsHours(_ date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = Double(comps.hour ?? 0)
        let min = Double(comps.minute ?? 0) / 60
        return hour + min
    }
}

