import SwiftUI

// MARK: - Duration Enums

enum DefaultDuration: String, CaseIterable, Identifiable {
    case indefinitely = "Indefinitely"
    case divider1
    case fiveMinutes = "5 minutes"
    case tenMinutes = "10 minutes"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case divider2
    case oneHour = "1 hour"
    case twoHours = "2 hours"
    case threeHours = "3 hours"
    case fourHours = "4 hours"
    case fiveHours = "5 hours"
    case sixHours = "6 hours"
    case sevenHours = "7 hours"
    case eightHours = "8 hours"
    case twelveHours = "12 hours"
    case twentyFourHours = "24 hours"

    var id: String { rawValue }

    var timeInterval: TimeInterval? {
        switch self {
        case .indefinitely: nil
        case .fiveMinutes: 5 * 60
        case .tenMinutes: 10 * 60
        case .fifteenMinutes: 15 * 60
        case .thirtyMinutes: 30 * 60
        case .oneHour: 60 * 60
        case .twoHours: 2 * 60 * 60
        case .threeHours: 3 * 60 * 60
        case .fourHours: 4 * 60 * 60
        case .fiveHours: 5 * 60 * 60
        case .sixHours: 6 * 60 * 60
        case .sevenHours: 7 * 60 * 60
        case .eightHours: 8 * 60 * 60
        case .twelveHours: 12 * 60 * 60
        case .twentyFourHours: 24 * 60 * 60
        case .divider1, .divider2: nil
        }
    }
}

// MARK: - Content View

struct DurationSettingsView: View {
    @AppStorage("defaultDuration")
    private var defaultDurationRaw: String = DefaultDuration.indefinitely.rawValue

    @AppStorage("isCustomDurationEnabled")
    private var isCustomDurationEnabled: Bool = false

    @AppStorage("customHours")
    private var customHours: Int = 0

    @AppStorage("customMinutes")
    private var customMinutes: Int = 30

    // Pane identifier for notification
    private let paneIdentifier = "duration"

    // Computed property for total duration display
    private var totalDurationText: String {
        if customHours == 0, customMinutes == 0 {
            return "No duration set"
        }

        var components: [String] = []

        // Format hours
        if customHours > 0 {
            let hoursMeasurement = Measurement(value: Double(customHours), unit: UnitDuration.hours)
            // .wide style gives "1 hour" or "2 hours"
            components.append(hoursMeasurement.formatted(.measurement(width: .wide)))
        }

        // Format minutes
        if customMinutes > 0 {
            let minutesMeasurement = Measurement(value: Double(customMinutes), unit: UnitDuration.minutes)
            components.append(minutesMeasurement.formatted(.measurement(width: .wide)))
        }

        // Use ListFormatter to join the components.
        // It will automatically use "and" (or the localized equivalent).
        // e.g., ["1 hour", "30 minutes"] -> "1 hour and 30 minutes"
        // e.g., ["1 hour"] -> "1 hour"
        let formatter = ListFormatter()
        return formatter.string(from: components) ?? "No duration set"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Default Duration Section
            HStack(alignment: .top, spacing: 12) {
                Text("Default Session Duration:")
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading, spacing: 6) {
                    Picker("", selection: $defaultDurationRaw) {
                        ForEach(DefaultDuration.allCases) { duration in
                            if duration.rawValue.contains("divider") {
                                Divider()
                            } else {
                                Text(duration.rawValue).tag(duration.rawValue)
                            }
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
            }

            Divider().padding(.vertical, 4)

            // Custom Duration Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text("Custom Duration:")
                        .frame(width: 200, alignment: .trailing)

                    Toggle("Enable Custom Duration", isOn: $isCustomDurationEnabled)
                        .help("Override the default duration with a custom value.")
                        .onChange(of: isCustomDurationEnabled) { _, _ in
                            notifyContentSizeChange()
                        }
                }

                if isCustomDurationEnabled {
                    HStack(spacing: 12) {
                        Spacer().frame(width: 200)

                        VStack(alignment: .leading, spacing: 12) {
                            // Hours Control
                            HStack(spacing: 8) {
                                Text("Hours:")
                                    .frame(width: 60, alignment: .trailing)

                                Stepper(value: $customHours, in: 0 ... 24) {
                                    Text("\(customHours)")
                                        .frame(width: 30, alignment: .center)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(4)
                                }
                                .fixedSize()
                            }

                            // Minutes Control
                            HStack(spacing: 8) {
                                Text("Minutes:")
                                    .frame(width: 60, alignment: .trailing)

                                Stepper(value: $customMinutes, in: 0 ... 55, step: 5) {
                                    Text("\(customMinutes)")
                                        .frame(width: 30, alignment: .center)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(4)
                                }
                                .fixedSize()
                            }

                            // Total Duration Display
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 14))

                                Text("Total: \(totalDurationText)")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
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

// MARK: - Preview

#Preview {
    DurationSettingsView()
        .frame(width: 600)
}
