import SwiftUI
import AppKit
import UserNotifications
import Combine

// MARK: - Caffeinate Service
class CaffeinateService: ObservableObject {
    @Published var isActive = false
    private var caffeinateProcess: Process?
    
    func toggle() {
        if isActive {
            stop()
        } else {
            start()
        }
    }
    
    private func start() {
        stop() // Ensure clean state
        
        caffeinateProcess = Process()
        caffeinateProcess?.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        caffeinateProcess?.arguments = ["-d"] // Prevent display sleep
        
        do {
            try caffeinateProcess?.run()
            DispatchQueue.main.async {
                self.isActive = true
            }
            print("✅ Caffeinate started successfully")
            sendNotification(title: "Kawa Activated", message: "Your Mac will stay awake ☕")
        } catch {
            print("❌ Error starting caffeinate: \(error)")
        }
    }
    
    func stop() {
        if let process = caffeinateProcess, process.isRunning {
            process.terminate()
        }
        
        caffeinateProcess = nil
        
        let wasActive = isActive
        DispatchQueue.main.async {
            self.isActive = false
        }
        
        if wasActive {
            print("⏹️ Caffeinate stopped")
            sendNotification(title: "Kawa Deactivated", message: "Your Mac can now sleep")
        }
    }
  
    private func sendNotification(title: String, message: String) {
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
    
    deinit {
        stop()
    }
}

// MARK: - Menu Bar Manager
class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    var service = CaffeinateService()
    private var cancellable: AnyCancellable?
    
    override init() {
        super.init()
        print("🚀 Initializing MenuBarManager")
        setupMenuBar()
        
        // Observe service state changes
        cancellable = service.$isActive.sink { [weak self] active in
            self?.updateIcon(active: active)
        }
    }
    
    private func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let statusItem = statusItem else {
            print("❌ Failed to create status item")
            return
        }
        
        guard let button = statusItem.button else {
            print("❌ Failed to get status item button")
            return
        }
        
        print("✅ Status item created successfully")
        
        // Set initial icon
        updateIcon(active: false)
        
        // Set button action
        button.action = #selector(toggleCaffeinate)
        button.target = self
        
        // Create menu
        setupMenu()
        
        print("✅ Menu bar setup complete")
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        let toggleItem = NSMenuItem(
            title: "Activate Kawa",
            action: #selector(toggleCaffeinate),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(
            title: "About Kawa",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func createCoffeeIcon(filled: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        if filled {
            // Active state - filled coffee cup
            NSColor.controlAccentColor.setFill()
            NSColor.controlAccentColor.setStroke()
        } else {
            // Inactive state - empty coffee cup
            NSColor.clear.setFill()
            NSColor.labelColor.setStroke()
        }
        
        // Draw coffee cup
        let cupRect = NSRect(x: 2, y: 2, width: 10, height: 12)
        let cupPath = NSBezierPath(roundedRect: cupRect, xRadius: 1, yRadius: 1)
        cupPath.lineWidth = 1.5
        cupPath.fill()
        cupPath.stroke()
        
        // Draw handle
        NSColor.labelColor.setStroke()
        let handlePath = NSBezierPath()
        handlePath.move(to: NSPoint(x: 12, y: 10))
        handlePath.appendArc(
            withCenter: NSPoint(x: 14, y: 8),
            radius: 2,
            startAngle: 90,
            endAngle: 270,
            clockwise: true
        )
        handlePath.lineWidth = 1.5
        handlePath.stroke()
        
        // Draw steam if active
        if filled {
            NSColor.secondaryLabelColor.setStroke()
            for i in 0..<3 {
                let x = 4 + CGFloat(i * 2)
                let steamPath = NSBezierPath()
                steamPath.move(to: NSPoint(x: x, y: 15))
                steamPath.curve(
                    to: NSPoint(x: x + 0.5, y: 17),
                    controlPoint1: NSPoint(x: x - 0.3, y: 15.5),
                    controlPoint2: NSPoint(x: x + 0.3, y: 16.5)
                )
                steamPath.lineWidth = 1
                steamPath.stroke()
            }
        }
        
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
    
    private func updateIcon(active: Bool) {
        guard let button = statusItem?.button else { return }
        
        let icon = createCoffeeIcon(filled: active)
        button.image = icon
        
        // Update tooltip
        button.toolTip = active ? "Kawa active - Mac awake ☕" : "Kawa inactive - Click to activate ☕"
        
        // Update menu
        if let menu = statusItem?.menu,
           let toggleItem = menu.item(at: 0) {
            toggleItem.title = active ? "Deactivate Kawa" : "Activate Kawa"
        }
    }
    
    @objc private func toggleCaffeinate() {
        print("🖱️ Toggle caffeinate clicked")
        service.toggle()
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Kawa ☕"
        alert.informativeText = """
        Version 1.0
        
        A small app to keep your Mac awake.
        Uses macOS caffeinate command.
        
        Click the icon to toggle on/off.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        print("👋 Quitting Kawa")
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - App Delegate for proper initialization
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🎯 App finished launching")
        
        // Hide from dock
        NSApplication.shared.setActivationPolicy(.accessory)
  
        // Request notification permissions with more comprehensive handling
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Notification permission error: \(error)")
                    self?.handleNotificationPermissionDenied()
                } else if granted {
                    print("✅ Notifications authorized: \(granted)")
                } else {
                    print("❌ Notifications not granted")
                    self?.handleNotificationPermissionDenied()
                }
            }
        }
        
        // Initialize menu bar
        menuBarManager = MenuBarManager()
    }
    
    private func handleNotificationPermissionDenied() {
        // Optional: Show an alert to guide user to settings
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Notification Permissions Needed"
            alert.informativeText = "Please enable notifications for Kawa in System Settings > Notifications."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open System Preferences Notifications
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        menuBarManager?.service.stop()
    }
}

// MARK: - Main App
@main
struct KawaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { EmptyView() }
    }
}
