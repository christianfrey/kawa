import SwiftUI

// MARK: - Content View

struct BatterySettingsView: View {
    @AppStorage("deactivateOnLowBattery") private var deactivateOnLowBattery = false
    @AppStorage("batteryThreshold") private var batteryThreshold: Double = 50.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text("Low Power Mode:")
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Deactivate when battery is low", isOn: $deactivateOnLowBattery)

                    HStack {
                        Slider(value: $batteryThreshold, in: 10...90, step: 5)
                        Text("\(Int(batteryThreshold))%")
                            .frame(width: 40, alignment: .trailing)
                    }
                    .disabled(!deactivateOnLowBattery)
                    .foregroundColor(deactivateOnLowBattery ? .primary : .secondary)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
    }
}

// MARK: - Preview

#Preview {
    BatterySettingsView()
        .frame(width: 600)
}
