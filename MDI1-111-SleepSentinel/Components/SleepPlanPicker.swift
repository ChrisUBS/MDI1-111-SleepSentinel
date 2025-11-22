//
//  SleepPlanPicker.swift
//  SleepSentinel
//
//  Created by Christian Bonilla on 21/11/25.
//

import SwiftUI

struct SleepPlanPicker: View {
    var title: String
    @Binding var components: DateComponents
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "",
                    selection: Binding(
                        get: {
                            Calendar.current.date(from: components) ?? Date()
                        },
                        set: { newDate in
                            components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                        }
                    ),
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
