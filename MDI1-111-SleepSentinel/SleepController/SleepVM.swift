// SleepVM.swift
import Foundation
import HealthKit
import SwiftUI
internal import Combine
import UserNotifications

// ---------------------------------------------
// MARK: - Models
// ---------------------------------------------
struct SleepNight: Identifiable, Codable {
    var id: UUID = .init()
    var date: Date
    var inBed: TimeInterval?
    var asleep: TimeInterval?
    var bedtime: Date?
    var wake: Date?
    var midpoint: Date?
    var efficiency: Double?
}

struct SleepSettings: Codable {
    var targetBedtime: DateComponents
    var targetWake: DateComponents
    var midpointToleranceMinutes: Int = 45
    var remindersEnabled: Bool = false
}

// ---------------------------------------------
// MARK: - ViewModel
// ---------------------------------------------
@MainActor
final class SleepVM: ObservableObject {

    // Published state
    @Published var nights: [SleepNight] = []
    @Published var settings = SleepSettings(targetBedtime: .init(hour: 23, minute: 0),
                                           targetWake: .init(hour: 7, minute: 0))
    @Published var hkAuthorized: Bool = false
    @Published var lastUpdate: Date? = nil
    @Published var usingDemo: Bool = false

    // Motion fusion (keeping your existing)
    @Published var motionFusion = MotionFusion()
    @Published var inferredOnset: Date?
    @Published var inferredWake: Date?

    // Private properties
    private let store = HKHealthStore()
    private var anchor: HKQueryAnchor?
    private var timer = Timer()
    private var observers: [NSObjectProtocol] = []

    // Anchor storage path
    private var anchorURL: URL {
        FileManager.documentsDirectory.appendingPathComponent("hk_anchor.data")
    }

    // ---------------------------------------------
    // MARK: Init
    // ---------------------------------------------
    init() {
        loadAnchor()
        startDayChangeObservers()
        motionFusion.start()
        startFusionTimer()
    }

    // ---------------------------------------------
    // MARK: - Day & Timezone observers
    // ---------------------------------------------
    func startDayChangeObservers() {
        let center = NotificationCenter.default

        let obs1 = center.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [self] in
                self?.handleDayOrTZChange()
            }
        }

        let obs2 = center.addObserver(
            forName: .NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [self] in
                self?.handleDayOrTZChange()
            }
        }

        observers = [obs1, obs2]
    }

    func handleDayOrTZChange() {
        print("Day or timezone changed — recomputing aggregates.")

        var newNights: [SleepNight] = []
        let cal = Calendar.current

        for n in nights {
            guard let bedtime = n.bedtime,
                  let wake = n.wake else { continue }

            let inBed = wake.timeIntervalSince(bedtime)
            let asleep = n.asleep ?? 0
            let midpoint = asleep > 0 ? bedtime.addingTimeInterval(asleep / 2) : nil
            let comps = cal.dateComponents([.year, .month, .day], from: bedtime)
            let anchor = cal.date(from: comps) ?? n.date
            let eff = inBed > 0 ? asleep / inBed : nil

            newNights.append(
                SleepNight(
                    date: anchor,
                    inBed: inBed,
                    asleep: asleep,
                    bedtime: bedtime,
                    wake: wake,
                    midpoint: midpoint,
                    efficiency: eff
                )
            )
        }

        nights = newNights.sorted { $0.date > $1.date }
        saveCache()
    }

    // ---------------------------------------------
    // MARK: - Motion fusion timer
    // ---------------------------------------------
    func startFusionTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in self.updateInferredCandidates() }
        }
    }

    func updateInferredCandidates() {
        if let lastLow = motionFusion.lowActivityWindows.last {
            inferredOnset = lastLow.start
        }
        
        if let lastHigh = motionFusion.highActivityWindows.last {
            inferredWake = lastHigh.end
        }
    }

    // ---------------------------------------------
    // MARK: - Cache
    // ---------------------------------------------
    func saveCache() {
        let url = FileManager.documentsDirectory.appendingPathComponent("sleep_cache.json")
        do {
            let data = try JSONEncoder().encode(nights)
            try data.write(to: url, options: .atomic)
            print("Sleep cache saved.")
        } catch {
            print("Error saving cache:", error)
        }
    }

    func loadCache() {
        let url = FileManager.documentsDirectory.appendingPathComponent("sleep_cache.json")
        do {
            let data = try Data(contentsOf: url)
            let cached = try JSONDecoder().decode([SleepNight].self, from: data)
            nights = cached
            print("Loaded sleep cache with \(cached.count) nights.")
        } catch {
            print("No existing cache found or failed to load:", error)
        }
    }

    // -----------------------------------------------------
    // MARK: - Anchor load/save (correct approach)
    // -----------------------------------------------------

    /// Load HKQueryAnchor if exists
    func loadAnchor() {
        do {
            let data = try Data(contentsOf: anchorURL)
            if let savedAnchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data) {
                self.anchor = savedAnchor
                print("Loaded HKQueryAnchor")
            }
        } catch {
            print("No anchor found or failed to load:", error)
        }
    }

    /// Save HKQueryAnchor
    func saveAnchor(_ newAnchor: HKQueryAnchor?) {
        guard let newAnchor else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: newAnchor, requiringSecureCoding: true)
            try data.write(to: anchorURL, options: .atomic)
            print("Saved HKQueryAnchor")
        } catch {
            print("Failed to save anchor:", error)
        }
    }


    // ---------------------------------------------
    // MARK: - HealthKit Authorization
    // ---------------------------------------------
    func requestHKAuth() {
        guard HKHealthStore.isHealthDataAvailable() else {
            Task { await self.loadDemoData() }
            return
        }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        store.requestAuthorization(toShare: [], read: [sleepType]) { success, error in
            DispatchQueue.main.async {

                let authStatus = self.store.authorizationStatus(for: sleepType)

                // ------------------------------
                // Keeping your commented block
                // ------------------------------

                // Temporaly
                self.hkAuthorized = true
                self.startObservers()
                Task { @MainActor in await self.runAnchoredFetch() }

                // TODO: To be honest, I couldn't get this part to work :(.
//                if authStatus == .sharingAuthorized {
//                    self.hkAuthorized = true
//                    self.startObservers()
//                    Task { @MainActor in await self.runAnchoredFetch() }
//                } else {
//                    self.hkAuthorized = false
//                    print("HealthKit access NOT granted")
//                }
            }
        }
    }

    // ---------------------------------------------
    // MARK: - Observer Query
    // ---------------------------------------------
    func startObservers() {
        #if targetEnvironment(simulator)
        print("Simulator: skipping HKObserverQuery")
        return
        #else
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let q = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, _, _ in
            guard let self else { return }
            Task { @MainActor in await self.runAnchoredFetch() }
        }

        store.execute(q)
        #endif
    }

    // ---------------------------------------------
    // MARK: - Anchored Fetch
    // ---------------------------------------------
    func runAnchoredFetch() async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let handler: @Sendable (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void =
        { [weak self] _, samples, _, newAnchor, _ in
            guard let self else { return }

            Task { @MainActor in
                if let newAnchor {
                    self.anchor = newAnchor
                    self.saveAnchor(newAnchor)
                }

                let casted = (samples as? [HKCategorySample]) ?? []
                self.process(casted)
            }
        }

        let q = HKAnchoredObjectQuery(type: sleepType,
                                      predicate: nil,
                                      anchor: anchor,
                                      limit: HKObjectQueryNoLimit,
                                      resultsHandler: handler)

        store.execute(q)
    }

    // ---------------------------------------------
    // MARK: - Process Samples
    // ---------------------------------------------
    @MainActor private func process(_ samples: [HKCategorySample]) {

        let cal = Calendar.current

        let grouped = Dictionary(grouping: samples) { sample -> Date in
            let comps = cal.dateComponents([.year, .month, .day], from: sample.startDate)
            return cal.date(from: comps)!
        }

        for (date, segs) in grouped {

            // Remove old entry if exists (prevent duplicates)
            if let idx = nights.firstIndex(where: { cal.isDate($0.date, inSameDayAs: date) }) {
                nights.remove(at: idx)
            }

            let inBedSegs = segs.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }

            let asleepSegs = segs.filter {
                $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
            }

            let totalInBed = inBedSegs.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let totalAsleep = asleepSegs.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let bedtime = segs.map { $0.startDate }.min()
            let wake = segs.map { $0.endDate }.max()

            let midpoint = (bedtime != nil && totalAsleep > 0)
                ? bedtime!.addingTimeInterval(totalAsleep / 2)
                : nil

            let eff = totalInBed > 0 ? totalAsleep / totalInBed : nil

            nights.append(
                SleepNight(date: date,
                           inBed: totalInBed,
                           asleep: totalAsleep,
                           bedtime: bedtime,
                           wake: wake,
                           midpoint: midpoint,
                           efficiency: eff)
            )
        }

        nights.sort { $0.date > $1.date }
        lastUpdate = Date()
        saveCache()
    }

    // ---------------------------------------------
    // MARK: - CSV Export
    // ---------------------------------------------
    func exportCSV() -> URL? {
        let header = "date,inBed,asleep,bedtime,wake,midpoint,efficiency\n"
        var csv = header

        let df = ISO8601DateFormatter()

        for n in nights {
            csv += "\(df.string(from: n.date)),\(n.inBed ?? 0),\(n.asleep ?? 0),\(n.bedtime.map(df.string) ?? ""),\(n.wake.map(df.string) ?? ""),\(n.midpoint.map(df.string) ?? ""),\(n.efficiency ?? 0)\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sleep.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // ---------------------------------------------
    // MARK: - Demo Data
    // ---------------------------------------------
    func loadDemoData() async {
        let demo = DemoData.load()
        await MainActor.run {
            usingDemo = true
            nights = demo
            lastUpdate = Date()
        }
        saveCache()
    }
}

// ---------------------------------------------
// MARK: - Metrics Extensions
// ---------------------------------------------
extension SleepVM {
    var midpointStdDev7d: Double? {
        let last7 = Array(nights.prefix(7))
        let mids = last7.compactMap { $0.midpoint?.timeIntervalSinceReferenceDate }
        guard mids.count >= 2 else { return nil }

        let mean = mids.reduce(0,+) / Double(mids.count)
        let variance = mids.map { pow($0 - mean, 2) }.reduce(0,+) / Double(mids.count)
        return sqrt(variance) / 60.0
    }
}

extension SleepVM {
    var socialJetlag: Double? {
        let last14 = Array(nights.prefix(14))

        let weekdayMids = last14.filter {
            let w = Calendar.current.component(.weekday, from: $0.date)
            return w != 1 && w != 7
        }.compactMap { $0.midpoint }

        let weekendMids = last14.filter {
            let w = Calendar.current.component(.weekday, from: $0.date)
            return w == 1 || w == 7
        }.compactMap { $0.midpoint }

        guard !weekdayMids.isEmpty && !weekendMids.isEmpty else { return nil }

        let avgWeekday = weekdayMids.map { $0.timeIntervalSinceReferenceDate }.reduce(0,+) / Double(weekdayMids.count)
        let avgWeekend = weekendMids.map { $0.timeIntervalSinceReferenceDate }.reduce(0,+) / Double(weekendMids.count)

        return abs(avgWeekend - avgWeekday) / 3600.0
    }
}

extension SleepVM {
    var regularityIndex: Double? {
        guard !nights.isEmpty else { return nil }

        let cal = Calendar.current
        let today = Date()

        guard let bed = cal.date(from: settings.targetBedtime),
              let wake = cal.date(from: settings.targetWake)
        else { return nil }

        let bedTime = cal.nextDate(after: today, matching: settings.targetBedtime, matchingPolicy: .nextTimePreservingSmallerComponents)!
        let wakeTime = cal.nextDate(after: today, matching: settings.targetWake, matchingPolicy: .nextTimePreservingSmallerComponents)!

        let targetMid = bedTime.addingTimeInterval(wakeTime.timeIntervalSince(bedTime) / 2)
        let tolerance = Double(settings.midpointToleranceMinutes) * 60

        let valid = nights.filter {
            guard let mid = $0.midpoint else { return false }
            return abs(mid.timeIntervalSince(targetMid)) <= tolerance
        }

        return Double(valid.count) / Double(nights.count)
    }
}

extension SleepVM {
    var chronotype: String {
        let mids = nights.prefix(7).compactMap { $0.midpoint }
        guard !mids.isEmpty else { return "No data" }

        let hours = mids.map {
            let comps = Calendar.current.dateComponents([.hour,.minute], from: $0)
            return Double(comps.hour ?? 0) + Double((comps.minute ?? 0))/60
        }

        let avg = hours.reduce(0,+) / Double(hours.count)

        switch avg {
        case ..<2.0: return "Early Chronotype"
        case 2.0..<4.0: return "Intermediate Chronotype"
        default: return "Evening Chronotype"
        }
    }
}

extension SleepVM {
    var sleepPlanAdherence: Double? {
        guard !nights.isEmpty else { return nil }

        let cal = Calendar.current
        let tolerance = Double(settings.midpointToleranceMinutes) * 60

        guard let targetBed = cal.date(from: settings.targetBedtime) else { return nil }

        let valid = nights.filter {
            guard let bedtime = $0.bedtime else { return false }
            return abs(bedtime.timeIntervalSince(targetBed)) <= tolerance
        }

        return Double(valid.count) / Double(nights.count)
    }
}

// ---------------------------------------------
// MARK: - Notification Scheduling
// ---------------------------------------------
extension SleepVM {
    func scheduleBedtimeReminder() {
        guard settings.remindersEnabled else { return }

        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert,.sound]) { granted, _ in
            guard granted else { return }
        }

        var comps = settings.targetBedtime
        if let minute = comps.minute {
            comps.minute = minute - 10 < 0 ? 50 : minute - 10
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Bedtime Reminder"
        content.body = "Your target bedtime is coming up."

        let req = UNNotificationRequest(identifier: "bedtimeReminder", content: content, trigger: trigger)
        center.add(req)
    }
}

// ---------------------------------------------
// MARK: - FileManager Helper
// ---------------------------------------------
extension FileManager {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
