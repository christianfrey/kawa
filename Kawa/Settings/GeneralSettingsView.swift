import SwiftUI

struct GeneralSettingsView: View {
    @StateObject private var loginItemManager = LoginItemManager.shared
    @StateObject private var sleepManager = SleepPreventionManager.shared
    @State private var preventLidSleep = false
    @AppStorage("quickStartClickMode") private var quickStartClickModeRaw: String = QuickStartClickMode.right.rawValue
    
    private var quickStartClickMode: Binding<QuickStartClickMode> {
        Binding(
            get: { QuickStartClickMode(rawValue: quickStartClickModeRaw) ?? .right },
            set: { quickStartClickModeRaw = $0.rawValue }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // GroupBox("General") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch Kawa at login", isOn: Binding(
                        get: { loginItemManager.isEnabled },
                        set: { _ in loginItemManager.toggle() }
                    ))
                    // .help("Launches Kawa automatically when your Mac starts up")
                    
                    Toggle("Activate Kawa", isOn: Binding(
                        get: { sleepManager.isPreventingSleep },
                        set: { _ in sleepManager.toggle() }
                    ))
                    
                    Toggle("Prevent system sleep when display is closed", isOn: Binding(
                        get: { preventLidSleep },
                        set: { newValue in
                            preventLidSleep = newValue
                            ClosedDisplayManager.setEnabled(newValue)
                        }
                    ))
                    // .help("Keeps your Mac awake even when the display is closed (clamshell mode)")
                }
                .padding()
            // }

            Form {
                Picker("Quickstart via Menu Bar Icon", selection: quickStartClickMode) {
                    Text("Right click").tag(QuickStartClickMode.right)
                    Text("Left click").tag(QuickStartClickMode.left)
                }
                .pickerStyle(.menu)
            }
            .padding()

            // GroupBox("Power Management") {
            //     VStack(alignment: .leading, spacing: 8) {
            //         HStack {
            //             Image(systemName: sleepManager.isPreventingSleep ? "moon.fill" : "moon")
            //                 .foregroundColor(sleepManager.isPreventingSleep ? .orange : .secondary)
            //             Text(sleepManager.statusDescription)
            //                 .font(.caption)
            //                 .foregroundColor(.primary)
            //             Spacer()
            //         }

            //         HStack(spacing: 16) {
            //             HStack {
            //                 Image(systemName: sleepManager.isOnBattery ? "battery.100" : "bolt.fill")
            //                     .foregroundColor(sleepManager.isOnBattery ? .orange : .green)
            //                 Text(sleepManager.isOnBattery ? "Battery" : "AC Power")
            //                     .font(.caption2)
            //             }
            //             HStack {
            //                 Image(systemName: sleepManager.hasExternalDisplay ? "display" : "laptopcomputer")
            //                     .foregroundColor(sleepManager.hasExternalDisplay ? .blue : .secondary)
            //                 Text(sleepManager.hasExternalDisplay ? "External Display" : "Built-in Only")
            //                     .font(.caption2)
            //             }
            //         }

//                    if sleepManager.isPreventingSleep {
//                        Text("🚀 Advanced sleep prevention active - works on battery and without external display")
//                            .font(.caption2)
//                            .foregroundColor(.green)
//                            .padding(.top, 2)
//                    }
//
//                    Text("When enabled, your Mac will stay awake even with the lid closed on battery power, allowing background processes to continue running.")
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                        .fixedSize(horizontal: false, vertical: true)

            //     }
            //     .padding()
            // }

            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsView()
}
