//
//  ChronotypeCard.swift
//  SleepSentinel
//
//  Created by Christian Bonilla on 21/11/25.
//

import SwiftUI

struct ChronotypeCard: View {
    @EnvironmentObject var vm: SleepVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chronotype")
                .font(.headline)
            
            Text(vm.chronotype)
                .font(.title3.weight(.semibold))
            
            Text(description(for: vm.chronotype))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    func description(for type: String) -> String {
        switch type {
        case "Early Chronotype":
            return "You tend to sleep and wake earlier than average."
        case "Intermediate Chronotype":
            return "Your sleep timing falls near the population average."
        case "Evening Chronotype":
            return "You tend to sleep and wake later than average."
        default:
            return "Not enough data to determine your chronotype."
        }
    }
}

