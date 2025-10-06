import Foundation
import IOKit.ps

@MainActor
class BatteryMonitor: ObservableObject {
    
    @Published private(set) var isOnBattery: Bool = false
    @Published private(set) var batteryLevel: Int = 100
    
    private var powerSourceRunLoopSource: CFRunLoopSource?
    var onStatusChange: (() -> Void)?
    
    init() {
        updateBatteryStatus()
        setupPowerSourceNotification()
    }
    
    deinit {
        if let source = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
    
    // MARK: - Public Methods
    
    func updateBatteryStatus() {
        let powerInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(powerInfo).takeRetainedValue() as [CFTypeRef]
        
        var isOnAC = false
        var currentBatteryLevel = 100
        
        for source in sources {
            guard let dict = source as? [String: Any] else { continue }
            
            // Check if on AC power
            if dict[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue {
                isOnAC = true
            }
            
            // Get battery level
            if let currentCapacity = dict[kIOPSCurrentCapacityKey] as? Int,
               let maxCapacity = dict[kIOPSMaxCapacityKey] as? Int,
               maxCapacity > 0 {
                currentBatteryLevel = (currentCapacity * 100) / maxCapacity
            }
        }
        
        self.isOnBattery = !isOnAC
        self.batteryLevel = currentBatteryLevel
        
        // print("🔋 Battery status: \(batteryLevel)%, isOnBattery: \(isOnBattery)")
    }
    
    func shouldDeactivatePrevention() -> Bool {
        let deactivateOnLowBattery = UserDefaults.standard.bool(forKey: "deactivateOnLowBattery")
        guard deactivateOnLowBattery && isOnBattery else { return false }
        
        let threshold = UserDefaults.standard.double(forKey: "batteryThreshold")
        return Double(batteryLevel) < threshold
    }
    
    // MARK: - Private Methods
    
    private func setupPowerSourceNotification() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        powerSourceRunLoopSource = IOPSNotificationCreateRunLoopSource(batteryMonitorCallback, context)?.takeRetainedValue()
        
        if let source = powerSourceRunLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
    
    internal func handlePowerSourceChange() {
        updateBatteryStatus()
        onStatusChange?()
    }
}

// MARK: - C Callback Function
private func batteryMonitorCallback(context: UnsafeMutableRawPointer?) {
    guard let context = context else { return }
    
    let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
    
    DispatchQueue.main.async {
        monitor.handlePowerSourceChange()
    }
}
