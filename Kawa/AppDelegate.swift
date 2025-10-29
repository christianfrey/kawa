import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_: Notification) {
        print("🎯 App finished launching")

        // Hide from dock
        NSApplication.shared.setActivationPolicy(.accessory)

        // Init menu bar manager
        menuBarManager = MenuBarManager()

        // menuBarManager?.settingsWindowController.show(pane: "general")
    }
}
