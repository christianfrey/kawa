import SwiftUI

enum SettingsTab: Int {
    case general
    case about
}

class SettingsState: ObservableObject {
    @Published var selectedTab: SettingsTab = .general
}

@main
struct KawaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var service = CaffeinateService()
    
    @StateObject private var settingsState = SettingsState()
    @Environment(\.openSettings) private var openSettings
    @State private var isActive = false

    var body: some Scene {

        MenuBarExtra {

            let toggleCaffeinateName = isActive ? "Deactivate Kawa" : "Activate Kawa"
            Button(toggleCaffeinateName) {
                print("🖱️ Toggle caffeinate clicked")
                toggleCaffeinate()
            }
            
            Divider()
            
            Button("About Kawa") {
                settingsState.selectedTab = .about
                openSettings()
                NSApp.activate(ignoringOtherApps: true) // TODO: fixme
                // Ensure Settings window appears in front
                // window.orderFrontRegardless()
            }
            
            // SettingsLink {
            //     Text("Settings…")
            // }
            Button("Settings…") {
                // selectedSettingsTab = .general
                settingsState.selectedTab = .general // TODO: remove me if other tabs are added
                openSettings()
                NSApp.activate(ignoringOtherApps: true) // TODO: fixme
                // Ensure Settings window appears in front
                // window.orderFrontRegardless()
            }
            .keyboardShortcut(",", modifiers: [.command])
            
            Divider()
            
            Button("Quit") {
                print("👋 Quitting Kawa")
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
            
        } label: {
            let iconName = isActive ? "CoffeeCupHot" : "CoffeeBean"
            Image(iconName)
                // Let the system automatically handle icon color for Light/Dark Mode
                .renderingMode(.template)
        }
        
        Settings {
            SettingsView(settingsState: settingsState)
        }
    }
    
    func toggleCaffeinate() {
        isActive.toggle()
        service.toggle()
        print("🖱️ Caffeinate toggled: \(isActive)")
    }
}
