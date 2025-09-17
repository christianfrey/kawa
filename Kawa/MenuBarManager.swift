import SwiftUI
import Combine

class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    var service = CaffeinateService()
    private var cancellable: AnyCancellable?
    var settingsWindowController: SettingsWindowController?
    
    override init() {
        super.init()
        print("🚀 Initializing MenuBarManager")
        setupMenuBar()
        
        // Observe service state changes
        cancellable = service.$isActive.sink { [weak self] active in
            self?.updateIcon(isActive: active)
        }
    }
    
    private func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let statusItem = statusItem else {
            print("❌ Failed to create status item")
            return
        }
        
        guard let button = statusItem.button else {
            print("❌ Failed to get status item button")
            return
        }
        
        print("✅ Status item created successfully")
        
        // Set initial icon
        updateIcon(isActive: false)
        
        // Set button action
        button.action = #selector(toggleCaffeinate)
        button.target = self
        
        // Create menu
        setupMenu()
        
        print("✅ Menu bar setup complete")
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        let toggleItem = NSMenuItem(
            title: "Activate Kawa",
            action: #selector(toggleCaffeinate),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(
            title: "About Kawa",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func updateIcon(isActive: Bool) {
        guard let button = statusItem?.button else { return }
        
        // Choose the appropriate image based on the active state
        let imageName = isActive ? "CoffeeCupHot" : "CoffeeCupCold"
        let image = NSImage(named: imageName)
        
        // Let the system automatically handle icon color for Light/Dark Mode
        image?.isTemplate = true
        
        button.image = image
        
        // Update menu
        if let menu = statusItem?.menu,
           let toggleItem = menu.item(at: 0) {
            toggleItem.title = isActive ? "Deactivate Kawa" : "Activate Kawa"
        }
    }
    
    @objc private func toggleCaffeinate() {
        print("🖱️ Toggle caffeinate clicked")
        service.toggle()
    }
    
    @objc private func showSettings() {
        print("⚙️ Settings menu clicked")
        if settingsWindowController == nil {
            print("🆕 Creating SettingsWindowController (general)")
            settingsWindowController = SettingsWindowController()
        } else {
            print("♻️ Reusing existing SettingsWindowController")
        }
        settingsWindowController?.showWindowWithTab(.general)
    }

    @objc private func showAbout() {
        print("ℹ️ About menu clicked")
        if settingsWindowController == nil {
            print("🆕 Creating SettingsWindowController (about)")
            settingsWindowController = SettingsWindowController()
        } else {
            print("♻️ Reusing existing SettingsWindowController")
        }
        settingsWindowController?.showWindowWithTab(.about)
    }

    
    @objc private func quitApp() {
        print("👋 Quitting Kawa")
        NSApplication.shared.terminate(nil)
    }
}
