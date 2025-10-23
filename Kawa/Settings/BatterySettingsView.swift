import SwiftUI

// MARK: - Content View

struct BatterySettingsView: View {
    // @AppStorage("activateOnACPower") private var activateOnACPower = false
    // @AppStorage("deactivateOnACPower") private var deactivateOnACPower = false
    // @AppStorage("deactivateOnLowPowerMode") private var deactivateOnLowPowerMode = false
    @AppStorage("deactivateOnLowBattery") private var deactivateOnLowBattery = false
    @AppStorage("batteryThreshold") private var batteryThreshold: Double = 50.0
    @StateObject private var batteryMonitor = BatteryMonitor()

    // Pane identifier for notification
    private let paneIdentifier = "battery"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Current Battery Status Card
            HStack(alignment: .top, spacing: 12) {
                BatteryStatusCard(
                    isOnBattery: batteryMonitor.isOnBattery,
                    batteryLevel: batteryMonitor.batteryLevel,
                )
            }

            Divider()
                .padding(.vertical, 4)

            // AC Power Auto-Activation
            // HStack(alignment: .top, spacing: 12) {
            //     Text("AC Power Mode:")
            //         .frame(width: 200, alignment: .trailing)

            //     VStack(alignment: .leading, spacing: 8) {
            //         Toggle("Activate when plugged", isOn: $activateOnACPower)
            //             .help("Automatically enable sleep prevention when connecting power adapter")

            //         Text("Sleep prevention will start when you plug in the power adapter.")
            //             .font(.caption)
            //             .foregroundColor(activateOnACPower ? .secondary : .gray)
            //     }
            // }

            // // AC Power Auto-Deactivation
            // HStack(alignment: .top, spacing: 12) {
            //     Text("")
            //         .frame(width: 200, alignment: .trailing)

            //     VStack(alignment: .leading, spacing: 8) {
            //         Toggle("Deactivate when unplugged from AC", isOn: $deactivateOnACPower)
            //             .help("Automatically disable sleep prevention when disconnecting power adapter")

            //         Text("Sleep prevention will stop when you unplug the power adapter.")
            //             .font(.caption)
            //             .foregroundColor(deactivateOnACPower ? .secondary : .gray)
            //     }
            // }

            // Divider()
            //     .padding(.vertical, 4)

            // Low Battery Auto-Deactivation
            HStack(alignment: .top, spacing: 12) {
                Text("Low Battery Mode:")
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Deactivate when battery drops below threshold", isOn: $deactivateOnLowBattery)
                        .help("Automatically disable sleep prevention when battery drops below threshold")
                        .onChange(of: deactivateOnLowBattery) { _, _ in
                            notifyContentSizeChange()
                        }

                    if deactivateOnLowBattery {
                        HStack {
                            Slider(value: $batteryThreshold, in: 2 ... 99)
                                .frame(width: 150)
                            Text("\(Int(batteryThreshold))%")
                                .frame(width: 40, alignment: .trailing)
                        }

                        // Text("Sleep prevention will stop when battery drops below \(Int(batteryThreshold))%")
                        //     .font(.caption)
                        //     .foregroundColor(.secondary)
                    }
                }
            }

            // Low Power Mode Auto-Deactivation
            // HStack(alignment: .top, spacing: 12) {
            //     Text("")
            //         .frame(width: 200, alignment: .trailing)

            //     VStack(alignment: .leading, spacing: 8) {
            //         Toggle("Deactivate on Low Power Mode", isOn: $deactivateOnLowPowerMode)
            //             .help("Automatically disable sleep prevention when macOS Low Power Mode is enabled")

            //         Text("Sleep prevention will stop when Low Power Mode is activated in System Settings.")
            //             .font(.caption)
            //             .foregroundColor(deactivateOnLowPowerMode ? .secondary : .gray)
            //     }
            // }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
    }

    // MARK: - Notification Helper

    private func notifyContentSizeChange() {
        NotificationCenter.default.post(
            name: NSNotification.Name("SettingsPaneContentSizeChanged"),
            object: nil,
            userInfo: ["paneIdentifier": paneIdentifier],
        )
    }
}

// MARK: - Battery Status Card

struct BatteryStatusCard: View {
    let isOnBattery: Bool
    let batteryLevel: Int

    private var batteryColor: Color {
        if batteryLevel > 50 {
            .green
        } else if batteryLevel > 20 {
            .orange
        } else {
            .red
        }
    }

    private var batteryIcon: String {
        if !isOnBattery {
            "battery.100.bolt"
        } else if batteryLevel > 75 {
            "battery.100"
        } else if batteryLevel > 50 {
            "battery.75"
        } else if batteryLevel > 25 {
            "battery.50"
        } else {
            "battery.25"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("Battery Status:")
                .frame(width: 200, alignment: .trailing)

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    // Battery Icon
                    Image(systemName: batteryIcon)
                        .font(.system(size: 20))
                        .foregroundColor(isOnBattery ? batteryColor : .green)

                    // Battery Level
                    Text("\(batteryLevel)%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(batteryColor)

                    if batteryLevel < 20 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                }

                // Power Source
                Text("•")
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: isOnBattery ? "bolt.slash.circle.fill" : "bolt.circle.fill")
                        .font(.system(size: 16))
                    Text(isOnBattery ? "On Battery" : "Plugged In")
                        .font(.system(size: 12))
                }
                .foregroundColor(isOnBattery ? .orange : .green)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    BatterySettingsView()
        .frame(width: 600)
}
