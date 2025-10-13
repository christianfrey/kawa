import SwiftUI

// MARK: - Duration Enums

enum DefaultDuration: String, CaseIterable, Identifiable {
    case indefinitely = "Indefinitely"
    case fiveMinutes = "5 minutes"
    case tenMinutes = "10 minutes"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case oneHour = "1 hour"
    case twoHours = "2 hours"
    case fiveHours = "5 hours"
    case eightHours = "8 hours"
    case twelveHours = "12 hours"
    case twentyFourHours = "24 hours"

    var id: String { self.rawValue }

    var timeInterval: TimeInterval? {
        switch self {
        case .indefinitely:
            return nil
        case .fiveMinutes:
            return 5 * 60
        case .tenMinutes:
            return 10 * 60
        case .fifteenMinutes:
            return 15 * 60
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        case .twoHours:
            return 2 * 60 * 60
        case .fiveHours:
            return 5 * 60 * 60
        case .eightHours:
            return 8 * 60 * 60
        case .twelveHours:
            return 12 * 60 * 60
        case .twentyFourHours:
            return 24 * 60 * 60
        }
    }
}

enum DurationUnit: String, CaseIterable, Identifiable {
    case minutes, hours
    var id: Self { self }
}

// MARK: - Content View

struct DurationSettingsView: View {
    
    @AppStorage("defaultDuration")
    private var defaultDuration: DefaultDuration.RawValue = DefaultDuration.indefinitely.rawValue
    
    @AppStorage("isCustomDurationEnabled")
    private var isCustomDurationEnabled: Bool = false
    
    @AppStorage("customDurationValue")
    private var customDurationValue: Int = 30
    
    @AppStorage("customDurationUnit")
    private var customDurationUnit: DurationUnit = .minutes

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Default Duration
            HStack(alignment: .top, spacing: 12) {
                Text("Default Session Duration:")
                    .frame(width: 180, alignment: .trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Picker("", selection: $defaultDuration) {
                        ForEach(DefaultDuration.allCases) { duration in
                            Text(duration.rawValue).tag(duration.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                    .help("Set a default duration for a Kawa session.")
                    .disabled(isCustomDurationEnabled)
                    
                    Text("The session will automatically end after the selected duration.")
                        .font(.caption)
                        .foregroundColor(isCustomDurationEnabled ? .gray : .secondary)
                }
                
                Spacer()
            }
            
            Divider().padding(.vertical, 4)
            
            // Custom Duration
            HStack(alignment: .top, spacing: 12) {
                Text("Custom Duration:")
                    .frame(width: 180, alignment: .trailing)
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable Custom Duration", isOn: $isCustomDurationEnabled)
                        .help("Override the default duration with a custom value.")
                    
                    HStack {
                        TextField("Value", value: $customDurationValue, formatter: NumberFormatter())
                            .frame(width: 50)
                            .multilineTextAlignment(.trailing)
                        
                        Picker("Unit", selection: $customDurationUnit) {
                            Text("minutes").tag(DurationUnit.minutes)
                            Text("hours").tag(DurationUnit.hours)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fixedSize()
                    }
                    .disabled(!isCustomDurationEnabled)
                    .foregroundColor(isCustomDurationEnabled ? .primary : .gray)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
    }
}

// MARK: - Preview

#Preview {
    DurationSettingsView()
        .frame(width: 600)
}
