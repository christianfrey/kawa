import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Notification Toggle
            HStack(alignment: .top, spacing: 12) {
                Text("Notifications:")
                    .frame(width: 180, alignment: .trailing)
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable notifications", isOn: $notificationsEnabled)
                        .disabled(authorizationStatus == .denied)

                    Text("Turn on to receive notifications when sleep prevention starts or stops.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Divider().padding(.vertical, 4)

            // System Permissions
            HStack(alignment: .top, spacing: 12) {
                Text("System Permissions:")
                    .frame(width: 180, alignment: .trailing)

                VStack(alignment: .leading, spacing: 8) {
                    switch authorizationStatus {
                    case .authorized:
                        Label("Permissions granted", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .denied:
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Permissions denied", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("You need to grant permission in System Settings.")
                                .font(.caption)
                            Button("Open System Settings") {
                                openSystemSettings()
                            }
                        }
                    case .notDetermined:
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Permissions not requested", systemImage: "questionmark.circle.fill")
                                .foregroundColor(.orange)
                            Button("Request Permissions") {
                                requestNotificationPermission()
                            }
                        }
                    default:
                        Text("Unknown permission status.")
                    }
                }
                Spacer()
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: checkNotificationStatus)
        // Check when app becomes active (user returns from System Settings)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkNotificationStatus()
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                if settings.authorizationStatus == .denied {
                    self.notificationsEnabled = false
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            checkNotificationStatus()
        }
    }

    private func openSystemSettings() {
        // Open System Preferences Notifications
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
    }
}

// MARK: - Preview

#Preview {
    NotificationsSettingsView()
        .padding(20)
        .frame(width: 600, height: 300)
}
