import SwiftUI

// MARK: - Content View
struct BatterySettingsView: View {
    @AppStorage("deactivateOnLowBattery") private var deactivateOnLowBattery = false
    @AppStorage("batteryThreshold") private var batteryThreshold: Double = 50.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Checkbox for enabling/disabling the feature
            Toggle(isOn: $deactivateOnLowBattery) {
                Text("Deactivate prevention when battery level below:")
                    .font(.system(size: 13))
            }
            .toggleStyle(.checkbox)
            
            // Slider for battery threshold
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("10%")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(batteryThreshold))%")
                        .font(.system(size: 13, weight: .medium))
                    
                    Spacer()
                    
                    Text("90%")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $batteryThreshold, in: 10...90, step: 5)
                    .disabled(!deactivateOnLowBattery)
            }
        }
        .frame(width: 500, alignment: .center)
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
    }
}

// MARK: - Preview
#Preview {
    BatterySettingsView()
        .padding(20)
        .frame(width: 500)
}
