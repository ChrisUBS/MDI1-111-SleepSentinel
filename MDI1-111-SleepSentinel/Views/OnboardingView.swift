//
//  OnboardingView.swift
//  SleepSentinel
//
//  Created by Christian Bonilla on 21/11/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var vm: SleepVM
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // App title
                VStack(spacing: 8) {
                    Text("SleepSentinel")
                        .font(.largeTitle.bold())
                        .padding(.top, 40)
                    
                    Text("A privacy-first sleep tracker that analyzes your nightly patterns, duration, midpoint, and consistency.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                // Icon / illustration
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 10)
                
                // Explanation section
                VStack(alignment: .leading, spacing: 12) {
                    Text("What SleepSentinel Reads")
                        .font(.headline)
                    
                    Text("• Only your Sleep Analysis data from HealthKit\n• Used to compute duration, sleep midpoint, and consistency trends\n• Data is processed fully on your device\n• Nothing is uploaded or shared")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Buttons
                VStack(spacing: 16) {
                    Button {
                        vm.requestHKAuth()
                    } label: {
                        Text("Grant Health Access")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Button {
//                        Task { await vm.loadDemoData() }
                        // Temporaly
                        vm.requestHKAuth()
                    } label: {
                        Text("Continue with Demo Mode")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
    }
}
