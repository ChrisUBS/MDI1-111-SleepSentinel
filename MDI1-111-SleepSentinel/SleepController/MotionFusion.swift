import Foundation
import CoreMotion
internal import Combine

struct ActivityWindow {
    let start: Date
    let end: Date
}

final class MotionFusion: ObservableObject {
    private let activityManager = CMMotionActivityManager()
    
    @Published var lowActivityWindows: [ActivityWindow] = []
    @Published var highActivityWindows: [ActivityWindow] = []
    
    private var currentStart: Date?
    private var lastActivityWasLow = false
    private var lastActivityWasHigh = false
    
    private let lowActivityThresholdSec: TimeInterval = 20 * 60 // 20 min
    private let highActivityThresholdSec: TimeInterval = 5 * 60 // 5 min
    
    // MARK: - Start monitoring
    func start() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("MotionFusion: Motion not available (simulator?)")
            return
        }
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let act = activity else { return }
            self.handleActivity(act)
        }
    }
    
    // MARK: - Handle incoming motion events
    private func handleActivity(_ act: CMMotionActivity) {
        let now = Date()
        
        let isLow = act.stationary && !act.walking && !act.running && !act.automotive
        let isHigh = act.walking || act.running
        
        // ---------- LOW ACTIVITY WINDOW ----------
        if isLow {
            if !lastActivityWasLow { currentStart = now }
            lastActivityWasLow = true
            lastActivityWasHigh = false
            
            if let start = currentStart,
               now.timeIntervalSince(start) >= lowActivityThresholdSec {
                
                lowActivityWindows.append(ActivityWindow(start: start, end: now))
                print("MotionFusion: LOW window detected \(start) → \(now)")
                
                currentStart = nil
                lastActivityWasLow = false
            }
            return
        }
        
        // ---------- HIGH ACTIVITY WINDOW ----------
        if isHigh {
            if !lastActivityWasHigh { currentStart = now }
            lastActivityWasHigh = true
            lastActivityWasLow = false
            
            if let start = currentStart,
               now.timeIntervalSince(start) >= highActivityThresholdSec {
                
                highActivityWindows.append(ActivityWindow(start: start, end: now))
                print("MotionFusion: HIGH window detected \(start) → \(now)")
                
                currentStart = nil
                lastActivityWasHigh = false
            }
            return
        }
        
        // If activity is neutral (e.g. automotive) reset State
        lastActivityWasLow = false
        lastActivityWasHigh = false
        currentStart = nil
    }
}
