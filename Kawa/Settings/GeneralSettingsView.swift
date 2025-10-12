import SwiftUI

// MARK: - General Settings View // TODO: rename to - Content View ?

struct GeneralSettingsView: View {
    
    // MARK: - Properties
    
    @StateObject private var loginItemManager = LoginItemManager.shared
    
    @AppStorage("startSessionOnLaunch")
    private var startSessionOnLaunch: Bool = false
    
    @AppStorage("allowDisplaySleep")
    private var allowDisplaySleep: Bool = false
    
    @AppStorage("preventLidSleep")
    private var preventLidSleep: Bool = false
    
    @AppStorage("endSessionOnManualSleep")
    private var endSessionOnManualSleep: Bool = false
    
    @AppStorage("startSessionAfterWakingFromSleep")
    private var startSessionAfterWakingFromSleep: Bool = false
    
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
                    
                    Toggle("Allow display sleep", isOn: $allowDisplaySleep)
                        .help("Lets the display sleep even when Kawa is active.")
                    
                    Toggle("Prevent sleep when display is closed", isOn: isLidSleepPrevented)
                        .help("Keeps your Mac awake even with the lid closed (laptops only)")
                    
                    Toggle("End session on manual sleep", isOn: $endSessionOnManualSleep)
                        .help("Stops the Kawa session when you manually put your Mac to sleep.")
                    
                    Toggle("Start session after waking from sleep", isOn: $startSessionAfterWakingFromSleep)
                        .help("Automatically starts a new Kawa session when your Mac wakes up.")
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
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
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
        .frame(width: 600)
}
