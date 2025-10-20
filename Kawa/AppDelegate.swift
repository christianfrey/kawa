import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?

    func applicationDidFinishLaunching(_: Notification) {
        print("🎯 App finished launching")

        // Hide from dock
        NSApplication.shared.setActivationPolicy(.accessory)

        // Init menu bar manager
        menuBarManager = MenuBarManager()
    }
}
