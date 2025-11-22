//
//  ConsistencySummaryCard.swift
//  SleepSentinel
//
//  Created by Christian Bonilla on 21/11/25.
//

import SwiftUI

struct ConsistencySummaryCard: View {
    @EnvironmentObject var vm: SleepVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency Summary")
                .font(.headline)
            
            if let std = vm.midpointStdDev7d {
                Text("Midpoint variability (7 days): \(std, specifier: "%.0f") min")
                    .foregroundColor(.secondary)
            } else {
                Text("Midpoint variability (7 days): n/a")
                    .foregroundColor(.secondary)
            }
            
            if let jetlag = vm.socialJetlag {
                Text("Social jetlag (14 days): \(jetlag, specifier: "%.1f") hrs")
                    .foregroundColor(.secondary)
            } else {
                Text("Social jetlag (14 days): n/a")
                    .foregroundColor(.secondary)
            }
            
            if let reg = vm.regularityIndex {
                Text("Regularity: \(reg * 100, specifier: "%.0f")%")
                    .foregroundColor(.secondary)
            } else {
                Text("Regularity: n/a")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
