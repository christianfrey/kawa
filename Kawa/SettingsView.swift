import SwiftUI

// Represents the tabs in the settings window.
enum SettingsTab: Hashable {
    case general
    case about
}

struct SettingsView: View {
    @StateObject private var loginItemManager = LoginItemManager.shared
    @State private var selection: SettingsTab

    // Initialize the view with the tab that should be selected initially.
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
        .frame(width: 360, height: 250)
        .padding()
    }
}

struct GeneralSettingsView: View {
    @StateObject private var loginItemManager = LoginItemManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Application:")
                    .frame(width: 100, alignment: .trailing)
                Toggle("Launch at Login", isOn: Binding(
                    get: { loginItemManager.isEnabled },
                    set: { _ in loginItemManager.toggle() }
                ))
                .help("Launch Kawa automatically when your Mac starts up")
            }
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

    // Designated initializer for the settings window controller
    init(selectedTab: SettingsTab = .general) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Kawa Settings"
        window.isReleasedWhenClosed = false

        super.init(window: window) // window is attached here

        // Center the window on the main screen (avoiding menu bar and dock)
        centerWindow(window)

        // Initialize the selected tab
        self.currentTab = selectedTab
        window.contentViewController = NSHostingController(rootView: SettingsView(selectedTab: selectedTab))

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
        print("👀 Window shown with tab: \(tab)")
    }

    // Center the window on the main screen, considering the visible frame (excludes menu bar and dock)
    private func centerWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size

        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.midY - windowSize.height / 2
        window.setFrameOrigin(NSPoint(x: x, y: y))
        print("📌 Window centered at (\(x), \(y))")
    }
}
