import SwiftUI

struct NotificationsSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true

    var body: some View {
        Form {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .toggleStyle(SwitchToggleStyle())
                // .help("Turn on to receive notifications when sleep prevention starts or stops")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tabItem {
            Label("Notifications", systemImage: "bell")
        }
        .tag(SettingsTab.notifications)
    }
}

// MARK: - Preview

#Preview {
    NotificationsSettingsView()
}
