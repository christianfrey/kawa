import SwiftUI

@main
struct KawaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sleepManager = SleepPreventionManager.shared

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
