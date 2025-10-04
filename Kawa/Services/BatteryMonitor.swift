import Foundation
import IOKit.ps

class BatteryMonitor: ObservableObject {
    @Published var currentBatteryLevel: Int = 100
    @Published var isPluggedIn: Bool = true
    
    private var timer: Timer?
    
    init() {
        updateBatteryStatus()
        startMonitoring()
    }
    
    func startMonitoring() {
        // Update battery status every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateBatteryStatus()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateBatteryStatus() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        guard let source = sources.first else { return }
        
        let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as! [String: Any]
        
        // Get battery level
        if let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int,
           let maxCapacity = description[kIOPSMaxCapacityKey] as? Int,
           maxCapacity > 0 {
            currentBatteryLevel = (currentCapacity * 100) / maxCapacity
        }
        
        // Check if plugged in
        if let powerSource = description[kIOPSPowerSourceStateKey] as? String {
            isPluggedIn = (powerSource == kIOPSACPowerValue)
        }
    }
    
    func shouldDeactivatePrevention(threshold: Double, enabled: Bool) -> Bool {
        guard enabled && !isPluggedIn else { return false }
        return Double(currentBatteryLevel) < threshold
    }
    
    deinit {
        stopMonitoring()
    }
}
