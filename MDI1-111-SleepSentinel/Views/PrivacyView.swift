//
//  PrivacyView.swift
//  SleepSentinel
//
//  Created by Christian Bonilla on 21/11/25.
//

import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                Text("Privacy & Data Policy")
                    .font(.largeTitle.bold())
                    .padding(.top)
                
                Text("""
SleepSentinel is designed with privacy as a core principle. Your data stays on your device and is never uploaded, shared, or transmitted anywhere.

**What data we read**
• HealthKit Sleep Analysis samples  
• Used only to compute:  
   – nightly duration  
   – sleep midpoint  
   – efficiency  
   – consistency metrics  
• Motion data is optional and stays local

**How your data is stored**
• All processing happens on your device  
• No servers, no accounts, no cloud requirements  
• Local cache is saved in the app’s Documents directory

**Exporting your data**
• You control if and when data is exported  
• CSV exports are generated locally and shared through the iOS share sheet

**Deleting your data**
• You may reset all app data at any time
""")
                .font(.body)
                .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle("Privacy")
    }
}
