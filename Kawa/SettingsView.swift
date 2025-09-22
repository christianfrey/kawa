import SwiftUI

// Represents the tabs in the settings window.
enum SettingsTab: Hashable {
    case general
    case about
}

struct SettingsView: View {
    @StateObject private var loginItemManager = LoginItemManager.shared
    @State private var selection: SettingsTab

    init(selectedTab: SettingsTab) {
        _selection = State(initialValue: selectedTab)
    }

    var body: some View {
        TabView(selection: $selection) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(SettingsTab.general)

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 480, height: 400)
    }
}


struct GeneralSettingsView: View {
    @StateObject private var loginItemManager = LoginItemManager.shared
    @StateObject private var sleepManager = SleepPreventionManager.shared
    @State private var preventLidSleep = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // GroupBox("General") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch Kawa at login", isOn: Binding(
                        get: { loginItemManager.isEnabled },
                        set: { _ in loginItemManager.toggle() }
                    ))
                    .help("Launches Kawa automatically when your Mac starts up")
                    
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
                    .help("Keeps your Mac awake even when the display is closed (clamshell mode)")
                }
                .padding()
            // }

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


struct AboutView: View {
    var body: some View {
        // About content with app icon, name, version and a short description/link
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                .resizable()
                .frame(width: 96, height: 96)
                .cornerRadius(8)

            Text("Kawa")
                .font(.title2)
                .bold()

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .foregroundColor(.secondary)

            Text("Keep your Mac awake with style.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            if let url = URL(string: "https://github.com/christianfrey/kawa") {
                Link("GitHub Repository", destination: url)
                    .padding(.top, 6)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// Window controller that manages the settings window and allows selecting a tab before showing.
class SettingsWindowController: NSWindowController {
    private var currentTab: SettingsTab = .general
    private let desiredContentSize = NSSize(width: 480, height: 400)

    // Designated initializer for the settings window controller
    init(selectedTab: SettingsTab = .general) {
        let window = NSWindow(
            // contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
            contentRect: NSRect(origin: .zero, size: desiredContentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Kawa Settings"
        window.isReleasedWhenClosed = false

        super.init(window: window)

        // Initialize the selected tab
        self.currentTab = selectedTab
        window.contentViewController = NSHostingController(rootView: SettingsView(selectedTab: selectedTab))

        // Set window size to prevent UI issues when positioning the window
        window.setContentSize(desiredContentSize)
        window.minSize = desiredContentSize
        
        positionWindowNearTopCenter(window)

        print("✅ SettingsWindowController initialized with tab: \(selectedTab)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Update the window content to display the given tab
    func updateTab(_ tab: SettingsTab) {
        guard tab != currentTab else { return }
        currentTab = tab
        window?.contentViewController = NSHostingController(rootView: SettingsView(selectedTab: tab))
        print("🔄 Updated tab to: \(tab)")
    }

    // Show the window and activate the requested tab
    func showWindowWithTab(_ tab: SettingsTab) {
        guard let window = self.window else {
            print("❌ No window available!")
            return
        }

        updateTab(tab)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        // Ensure Settings window appears in front
        window.orderFrontRegardless()

        print("👀 Window shown with tab: \(tab)")
    }

    // Positions the window horizontally centered and vertically slightly towards the top of the screen
    private func positionWindowNearTopCenter(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size

        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.origin.y + screenFrame.height * 2/3 - windowSize.height / 2
        window.setFrameOrigin(NSPoint(x: x, y: y))
        print("📌 Window positioned near top-center at (\(x), \(y))")
    }
}
