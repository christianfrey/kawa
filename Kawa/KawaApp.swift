import SwiftUI

@main
struct KawaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sleepManager = SleepPreventionManager.shared
    @StateObject private var menuBarManager: MenuBarManager

    init() {
        self._menuBarManager = StateObject(wrappedValue: MenuBarManager())
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
