import SwiftUI
import UserNotifications

// MARK: - Content View

struct NotificationsSettingsView: View {
    @AppStorage("sessionReminderEnabled") private var sessionReminderEnabled: Bool = false
    @AppStorage("sessionReminderIntervalValue") private var sessionReminderIntervalValue: Int = 15
    @AppStorage("sessionReminderIntervalUnit") private var sessionReminderIntervalUnit: String = "minutes"
    @AppStorage("notifyOnActivation") private var notifyOnActivation = true
    @AppStorage("notifyOnDeactivation") private var notifyOnDeactivation = true
    @State private var authorizationStatus: UNAuthorizationStatus?

    // Pane identifier for notification
    private let paneIdentifier = "notifications"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Notification Toggle
            HStack(alignment: .top, spacing: 12) {
                Text("Send notification:")
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("When activated", isOn: $notifyOnActivation)
                        .disabled(authorizationStatus == .denied)

                    Toggle("When deactivated", isOn: $notifyOnDeactivation)
                        .disabled(authorizationStatus == .denied)
                }
            }

            Divider().padding(.vertical, 4)

            // Session Reminder
            HStack(alignment: .top, spacing: 12) {
                Text("Session Reminder:")
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable session reminder", isOn: $sessionReminderEnabled)
                        .disabled(authorizationStatus == .denied)

                    Text("Receive a notification at a regular interval while Kawa is active.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if sessionReminderEnabled {
                        HStack {
                            TextField("Interval", value: $sessionReminderIntervalValue, formatter: NumberFormatter())
                                .frame(width: 50)
                            Picker("", selection: $sessionReminderIntervalUnit) {
                                Text("minutes").tag("minutes")
                                Text("hours").tag("hours")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 120)
                        }
                    }
                }
            }

            Divider().padding(.vertical, 4)

            // System Permissions
            HStack(alignment: .top, spacing: 12) {
                Text("System Permissions:")
                    .frame(width: 200, alignment: .trailing)

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
                        Text("Unknown permission status")
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .onAppear(perform: checkNotificationStatus)
        .onChange(of: sessionReminderEnabled) { _, _ in notifyContentSizeChange() }
        .onChange(of: authorizationStatus) { _, _ in notifyContentSizeChange() }
        // Check when app becomes active (i.e. user returns from System Settings)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkNotificationStatus()
        }
    }

    private func notifyContentSizeChange() {
        NotificationCenter.default.post(
            name: NSNotification.Name("SettingsPaneContentSizeChanged"),
            object: nil,
            userInfo: ["paneIdentifier": paneIdentifier],
        )
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                authorizationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
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
        .frame(width: 600)
}
