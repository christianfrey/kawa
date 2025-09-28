import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    
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
        
    }
    
    private func handleNotificationPermissionDenied() {
        // Show an alert to guide user to settings
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
}
