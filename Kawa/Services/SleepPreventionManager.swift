import AppKit
import Combine
import Foundation
import IOKit.pwr_mgt
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

    @Published private(set) var hasExternalDisplay: Bool = false
    @Published private(set) var remainingTimeFormatted: String = ""

    private var deactivationDate: Date?
    private var countdownTimer: Timer?
    private let batteryMonitor: BatteryMonitor

    // Enum to define assertion types in a clean and safe way.
    private enum AssertionType: Hashable {
        case preventSystemSleep
        case preventDisplaySleep

        // https://developer.apple.com/documentation/iokit/iopmlib_h/iopmassertiontypes
        var name: CFString {
            switch self {
            // Prevents the system from sleeping automatically due to a lack of user activity
            case .preventSystemSleep: return "PreventUserIdleSystemSleep" as CFString
            // Prevents the display from dimming automatically
            case .preventDisplaySleep: return "PreventUserIdleDisplaySleep" as CFString
            }
        }

        var reason: CFString {
            switch self {
            case .preventSystemSleep: return "Kawa: Preventing system sleep" as CFString
            case .preventDisplaySleep: return "Kawa: Preventing display sleep" as CFString
            }
        }
    }

    // A single dictionary to manage all active assertions.
    private var activeAssertionIDs: [AssertionType: IOPMAssertionID] = [:]
    private var sessionTimer: Timer?

    private init() {
        // Initialize battery monitor without callback first
        batteryMonitor = BatteryMonitor()

        let shouldStartOnLaunch = UserDefaults.standard.bool(forKey: "startSessionOnLaunch")
        self.isPreventingSleep = shouldStartOnLaunch

        if shouldStartOnLaunch {
            print("🚀 Starting session on launch as per user preference.")
        }

        setupNotifications()
        updateDisplayStatus()
        updateSleepPrevention()

        // Set the callback after self is fully initialized
        batteryMonitor.onStatusChange = { [weak self] in
            Task { @MainActor in
                self?.handleBatteryStatusChange()
            }
        }
    }

    deinit {
        print("🛑 SleepPreventionManager deinit")
        // Ensure all assertions are released when the object is deinitialized.
        activeAssertionIDs.values.forEach { IOPMAssertionRelease($0) }
        activeAssertionIDs.removeAll()

        sessionTimer?.invalidate()
        countdownTimer?.invalidate()

        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Public Methods

    func toggle() {
        isPreventingSleep.toggle()
    }

    // MARK: - Battery Check

    private func handleBatteryStatusChange() {
        // If prevention is active and battery is now too low, disable it
        if isPreventingSleep && batteryMonitor.shouldDeactivatePrevention() {
            print("🔋 Battery too low (\(batteryMonitor.batteryLevel)%), disabling prevention")
            isPreventingSleep = false
            sendNotification(
                title: "Kawa",
                message: "Prevention disabled: battery level too low (\(batteryMonitor.batteryLevel)%)"
            )
        }
    }

    // MARK: - Core Logic

    /// The main function that decides which assertions should be active.
    private func updateSleepPrevention() {
        sessionTimer?.invalidate()
        countdownTimer?.invalidate()
        deactivationDate = nil
        remainingTimeFormatted = ""

        if isPreventingSleep {
            // Check battery level before starting prevention
            if batteryMonitor.shouldDeactivatePrevention() {
                print("🔋 Prevention skipped: battery level too low (\(batteryMonitor.batteryLevel)%)")
                isPreventingSleep = false
                sendNotification(
                    title: "Kawa",
                    message: "Prevention disabled: battery level too low (\(batteryMonitor.batteryLevel)%)"
                )
                return
            }

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
                deactivationDate = Date().addingTimeInterval(interval)

                let sessionTimer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.isPreventingSleep = false
                        print("⏳ Session ended automatically after \(durationLabel).")
                    }
                }
                RunLoop.current.add(sessionTimer, forMode: .common)
                self.sessionTimer = sessionTimer

                let countdownTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        self?.updateRemainingTime()
                    }
                }
                RunLoop.current.add(countdownTimer, forMode: .common)
                self.countdownTimer = countdownTimer
                updateRemainingTime()
            } else {
                remainingTimeFormatted = "Indefinite"
            }
        }

        // Determine the desired state for each assertion.
        let shouldPreventSystemSleep = isPreventingSleep
        let allowDisplaySleep = UserDefaults.standard.bool(forKey: "allowDisplaySleep")
        let shouldPreventDisplaySleep = isPreventingSleep && !allowDisplaySleep

        // Apply the desired state.
        manageAssertion(type: .preventSystemSleep, enable: shouldPreventSystemSleep)
        manageAssertion(type: .preventDisplaySleep, enable: shouldPreventDisplaySleep)
    }

    private func updateRemainingTime() {
        guard let deactivationDate = deactivationDate else {
            remainingTimeFormatted = ""
            return
        }

        let remaining = deactivationDate.timeIntervalSinceNow

        if remaining > 0 {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = .pad

            let remainingString = formatter.string(from: remaining) ?? ""

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let endTimeString = dateFormatter.string(from: deactivationDate)

            remainingTimeFormatted = "\(remainingString) (until \(endTimeString))"
        } else {
            remainingTimeFormatted = ""
            countdownTimer?.invalidate()
        }
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
        workspaceCenter.addObserver(
            self,
            selector: #selector(displayConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Listen for sleep/wake notifications
        workspaceCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        workspaceCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // print("📌 Notifications configured")
    }

    @objc private func systemWillSleep(_ notification: Notification) {
        guard UserDefaults.standard.bool(forKey: "endSessionOnManualSleep"),
            isPreventingSleep
        else { return }

        isPreventingSleep = false
        print("💤 System will sleep, ending session as per user preference.")
    }

    @objc private func systemDidWake(_ notification: Notification) {
        guard UserDefaults.standard.bool(forKey: "startSessionAfterWakingFromSleep"),
            !isPreventingSleep
        else { return }

        isPreventingSleep = true
        print("🌅 System did wake, starting session as per user preference.")
    }

    @objc private func displayConfigurationChanged() {
        // print("🔄 Display configuration changed, updating...")
        updateDisplayStatus()
    }

    private func updateDisplayStatus() {
        self.hasExternalDisplay = NSScreen.screens.count > 1
        // print("ℹ️ Current state: hasExternalDisplay=\(hasExternalDisplay)")
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
