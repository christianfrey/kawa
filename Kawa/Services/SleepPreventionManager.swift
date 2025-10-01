import Foundation
import IOKit.pwr_mgt
import IOKit.ps
import AppKit
import UserNotifications

@MainActor
class SleepPreventionManager: ObservableObject {
    static let shared = SleepPreventionManager()

    // MARK: - Published Properties
    
    @Published var isPreventingSleep: Bool = false {
        didSet {
            updateSleepPrevention()
        }
    }

    @Published private(set) var isOnBattery: Bool = false
    @Published private(set) var hasExternalDisplay: Bool = false

    // Enum to define assertion types in a clean and safe way.
    private enum AssertionType: Hashable {
        case preventSystemSleep
        case preventDisplaySleep
        //case preventNoIdle

        // https://developer.apple.com/documentation/iokit/iopmlib_h/iopmassertiontypes
        var name: CFString {
            switch self {
            // Prevents the system from sleeping automatically due to a lack of user activity
            case .preventSystemSleep: return "PreventUserIdleSystemSleep" as CFString
            // Prevents the display from dimming automatically
            case .preventDisplaySleep: return "PreventUserIdleDisplaySleep" as CFString
            // The system will not idle sleep when enabled (display may sleep).
            // Note that the system may sleep for other reasons.
            //case .preventNoIdle: return "NoIdleSleepAssertion" as CFString
            }
        }

        var reason: CFString {
            switch self {
            case .preventSystemSleep: return "Kawa: Preventing system sleep" as CFString
            case .preventDisplaySleep: return "Kawa: Preventing display sleep" as CFString
            //case .preventNoIdle: return "Kawa: Preventing idle sleep on battery" as CFString
            }
        }
    }

    // A single dictionary to manage all active assertions.
    private var activeAssertionIDs: [AssertionType: IOPMAssertionID] = [:]
    private var powerSourceRunLoopSource: CFRunLoopSource?
    private var sessionTimer: Timer?

    private init() {
        let shouldStartOnLaunch = UserDefaults.standard.bool(forKey: "startSessionOnLaunch")
        self.isPreventingSleep = shouldStartOnLaunch
        
        if shouldStartOnLaunch {
            print("🚀 Starting session on launch as per user preference.")
        }

        setupNotifications()
        updateSystemStatus()
        updateSleepPrevention()
    }

    deinit {
        print("🛑 SleepPreventionManager deinit")
        // Ensure all assertions are released when the object is deinitialized.
        activeAssertionIDs.values.forEach { IOPMAssertionRelease($0) }
        activeAssertionIDs.removeAll()
        
        sessionTimer?.invalidate()
        
        // Clean up power source notification
        if let source = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
        
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func toggle() {
        isPreventingSleep.toggle()
    }
    
    // MARK: - Core Logic

    /// The main function that decides which assertions should be active.
    private func updateSleepPrevention() {
        sessionTimer?.invalidate()

        if isPreventingSleep {
            let timeInterval: TimeInterval?
            let durationLabel: String

            if UserDefaults.standard.bool(forKey: "isCustomDurationEnabled") {
                let value = UserDefaults.standard.integer(forKey: "customDurationValue")
                let unit = UserDefaults.standard.string(forKey: "customDurationUnit") ?? "minutes"
                
                if value > 0 {
                    timeInterval = unit == "hours" ? TimeInterval(value * 3600) : TimeInterval(value * 60)
                    durationLabel = "\(value) \(unit)"
                } else {
                    timeInterval = nil
                    durationLabel = "indefinitely"
                }
            } else {
                let durationRaw = UserDefaults.standard.string(forKey: "defaultDuration") ?? DefaultDuration.indefinitely.rawValue
                let duration = DefaultDuration(rawValue: durationRaw) ?? .indefinitely
                timeInterval = duration.timeInterval
                durationLabel = duration.rawValue
            }
            
            if let interval = timeInterval {
                sessionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.isPreventingSleep = false
                        print("⏳ Session ended automatically after \(durationLabel).")
                    }
                }
            }
        }

        // Determine the desired state for each assertion.
        let shouldPreventSystemSleep = isPreventingSleep
        let shouldPreventDisplaySleep = isPreventingSleep
        //let shouldPreventNoIdle = isPreventingSleep && isOnBattery // Only if requested AND on battery.

        // Apply the desired state.
        manageAssertion(type: .preventSystemSleep, enable: shouldPreventSystemSleep)
        manageAssertion(type: .preventDisplaySleep, enable: shouldPreventDisplaySleep)
        //manageAssertion(type: .preventNoIdle, enable: shouldPreventNoIdle)
    }

    /// A single function to create or release an assertion.
    private func manageAssertion(type: AssertionType, enable: Bool) {
        if enable {
            // If an assertion of this type doesn't already exist, create it.
            guard activeAssertionIDs[type] == nil else { return }

            var assertionID: IOPMAssertionID = 0
            let result = IOPMAssertionCreateWithName(
                type.name,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                type.reason,
                &assertionID
            )

            if result == kIOReturnSuccess {
                activeAssertionIDs[type] = assertionID
                print("✅ Assertion created: \(type), id=\(assertionID)")
                if type == .preventSystemSleep {
                    startPreventingSleep()
                }
            } else {
                print("❌ Failed to create assertion: \(type)")
            }
        } else {
            // If an assertion of this type exists, release it.
            guard let assertionID = activeAssertionIDs.removeValue(forKey: type) else { return }

            IOPMAssertionRelease(assertionID)
            print("🗑️ Assertion released: \(type)")
            if type == .preventSystemSleep {
                stopPreventingSleep()
            }
        }
    }

    // MARK: - System Status & Notifications

    private func setupNotifications() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceCenter.addObserver(self, selector: #selector(systemStatusDidChange), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        
        // Listen for sleep/wake notifications
        workspaceCenter.addObserver(self, selector: #selector(systemWillSleep), name: NSWorkspace.willSleepNotification, object: nil)
        workspaceCenter.addObserver(self, selector: #selector(systemDidWake), name: NSWorkspace.didWakeNotification, object: nil)

        // Setup power source notification with C callback
        setupPowerSourceNotification()

        // print("📌 Notifications configured")
    }
    
    @objc private func systemWillSleep(_ notification: Notification) {
        guard UserDefaults.standard.bool(forKey: "endSessionOnManualSleep"),
            isPreventingSleep else { return }
        
        isPreventingSleep = false
        print("💤 System will sleep, ending session as per user preference.")
    }

    @objc private func systemDidWake(_ notification: Notification) {
        guard UserDefaults.standard.bool(forKey: "startSessionAfterWakingFromSleep"),
            !isPreventingSleep else { return }
        
        isPreventingSleep = true
        print("🌅 System did wake, starting session as per user preference.")
    }
    
    private func setupPowerSourceNotification() {
        // Create context to pass the instance
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        // Create the notification source with C callback
        powerSourceRunLoopSource = IOPSNotificationCreateRunLoopSource(powerSourceCallback, context)?.takeRetainedValue()
        
        if let source = powerSourceRunLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }

    /// Updates the system status (battery, screens) and re-evaluates assertions.
    @objc internal func systemStatusDidChange() {
        // print("🔄 System status changed, updating...")
        updateSystemStatus()
        updateSleepPrevention() // Re-apply the logic with the new state.
    }

    private func updateSystemStatus() {
        // Update battery status.
        let powerInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(powerInfo).takeRetainedValue() as [CFTypeRef]
        self.isOnBattery = !sources.contains {
            guard let dict = $0 as? [String: Any] else { return false }
            return dict[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
        }

        // Update display status.
        self.hasExternalDisplay = NSScreen.screens.count > 1

        // print("ℹ️ Current state: isOnBattery=\(isOnBattery), hasExternalDisplay=\(hasExternalDisplay)")
    }
    
    private func startPreventingSleep() {
        print("✅ Sleep prevention started successfully")
        sendNotification(title: "Kawa", message: "Sleep prevention activated")
    }
    
    private func stopPreventingSleep() {
        print("⏹️ Sleep prevention stopped")
        sendNotification(title: "Kawa", message: "Sleep prevention deactivated")
    }
    
    private func sendNotification(title: String, message: String) {

        // Check user preference
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        
        // Ensure notifications are authorized
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // Check if notifications are allowed
            guard settings.authorizationStatus == .authorized else {
                print("❌ Notifications not authorized")
                return
            }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = .default
            
            // Create a trigger (nil means deliver immediately)
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            
            // Add the notification request
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error sending notification: \(error)")
                } else {
                    print("✅ Notification sent successfully")
                }
            }
        }
    }
}

// MARK: - C Callback Function
// This function must be at the top level (not inside the class) to work with C APIs
private func powerSourceCallback(context: UnsafeMutableRawPointer?) {
    guard let context = context else { return }
    
    // Convert the context back to our manager instance
    let manager = Unmanaged<SleepPreventionManager>.fromOpaque(context).takeUnretainedValue()
    
    // Dispatch to main queue since we're using @MainActor
    DispatchQueue.main.async {
        manager.systemStatusDidChange()
    }
}
