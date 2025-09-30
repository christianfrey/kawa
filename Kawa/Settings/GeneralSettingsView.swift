import SwiftUI

// MARK: - General Settings View

struct GeneralSettingsView: View {
    
    // MARK: - Properties
    
    @StateObject private var loginItemManager = LoginItemManager.shared
    
    @AppStorage("startSessionOnLaunch")
    private var startSessionOnLaunch: Bool = false
    
    @AppStorage("preventLidSleep")
    private var preventLidSleep: Bool = false
    
    @AppStorage("quickStartClickMode")
    private var quickStartClickModeRaw: String = QuickStartClickMode.right.rawValue
    
    // MARK: - Computed Properties
    
    private var isLaunchAtLoginEnabled: Binding<Bool> {
        Binding(
            get: { loginItemManager.isEnabled },
            set: { _ in loginItemManager.toggle() }
        )
    }
    
    private var isLidSleepPrevented: Binding<Bool> {
        Binding(
            get: { preventLidSleep },
            set: { newValue in
                preventLidSleep = newValue
                ClosedDisplayManager.setEnabled(newValue)
            }
        )
    }
    
    private var quickStartClickMode: Binding<QuickStartClickMode> {
        Binding(
            get: { QuickStartClickMode(rawValue: quickStartClickModeRaw) ?? .right },
            set: { quickStartClickModeRaw = $0.rawValue }
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // General toggles
            HStack(alignment: .top, spacing: 12) {
                Text("Startup & Sleep Control:")
                    .frame(width: 180, alignment: .trailing)
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Launch Kawa at login", isOn: isLaunchAtLoginEnabled)
                        .help("Automatically starts Kawa when your Mac boots up")
                    
                    Toggle("Start session when app launches", isOn: $startSessionOnLaunch)
                        .help("Automatically activates Kawa when the application starts.")
                    
                    Toggle("Prevent sleep when display is closed", isOn: isLidSleepPrevented)
                        .help("Keeps your Mac awake even with the lid closed (laptops only)")
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Quick start picker
            HStack(alignment: .top, spacing: 12) {
                Text("Menu Icon Quickstart:")
                    .frame(width: 180, alignment: .trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Picker("", selection: quickStartClickMode) {
                        Text("Right click").tag(QuickStartClickMode.right)
                        Text("Left click").tag(QuickStartClickMode.left)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                    .help("Choose which click toggles Kawa directly")
                    
                    Text("The selected click will toggle Kawa, while the other will show the menu.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 0)
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: syncLidSleepState)
    }
    
    // MARK: - Methods
    
    private func syncLidSleepState() {
        // Sync the closed display state on appear
        ClosedDisplayManager.setEnabled(preventLidSleep)
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsView()
        .padding(20)
        .frame(width: 600, height: 300)
}
