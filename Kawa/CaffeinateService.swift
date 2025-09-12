import UserNotifications

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
