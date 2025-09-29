import SwiftUI

enum SettingsTab: Int {
    case general
    case notifications
    case about
}

class SettingsState: ObservableObject {
    @Published var selectedTab: SettingsTab = .general
}

@main
struct KawaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sleepManager = SleepPreventionManager.shared
    @StateObject private var settingsState = SettingsState()
    @StateObject private var menuBarManager: MenuBarManager
    
    init() {
        let settingsState = SettingsState()
        self._settingsState = StateObject(wrappedValue: settingsState)
        self._menuBarManager = StateObject(wrappedValue: MenuBarManager(settingsState: settingsState))
    }

    var body: some Scene {
        Settings {
            SettingsView(settingsState: settingsState)
        }
    }
}
