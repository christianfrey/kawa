import SwiftUI
import AppKit // MenuBarExtra does not support right-click handling, so use NSStatusBar
import Combine

// Defines which mouse click is used for quick-starting a session
enum QuickStartClickMode: String {
    case left = "left"
    case right = "right"
}

extension UserDefaults {
    private enum Keys {
        static let quickStartClickMode = "quickStartClickMode"
    }
    
    // Store and retrieve the user preference for quick-start click mode
    var quickStartClickMode: QuickStartClickMode {
        get {
            if let value = string(forKey: Keys.quickStartClickMode),
               let mode = QuickStartClickMode(rawValue: value) {
                return mode
            }
            return .right // Default mode: right-click quick-start
        }
        set {
            set(newValue.rawValue, forKey: Keys.quickStartClickMode)
        }
    }
}

@MainActor
class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private let sleepManager = SleepPreventionManager.shared
    private var settingsState: SettingsState
    
    var openSettingsAction: (() -> Void)?

    init(settingsState: SettingsState) {
        self.settingsState = settingsState
        super.init()
        setupMenuBarItem()
    }
    
    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            updateIcon()
            
            // Configure click handlers for left and right clicks
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Listen to sleep manager changes to update icon
        setupObservers()
    }
    
    private func setupObservers() {
        // Update icon when sleep state changes
        sleepManager.$isPreventingSleep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        
        let iconName = sleepManager.isPreventingSleep ? "CoffeeCupHot" : "CoffeeBean"
        if let image = NSImage(named: iconName) {
            image.isTemplate = true
            button.image = image
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        let mode = UserDefaults.standard.quickStartClickMode
        
        switch event.type {
        case .leftMouseUp:
            if mode == .left {
                print("🖱️ Left click → toggle Kawa")
                sleepManager.toggle()
            } else {
                print("🖱️ Left click → show menu")
                showMenu()
            }
        case .rightMouseUp:
            if mode == .right {
                print("🖱️ Right click → toggle Kawa")
                sleepManager.toggle()
            } else {
                print("🖱️ Right click → show menu")
                showMenu()
            }
        default:
            break
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        
        // Toggle menu item
        let toggleTitle = sleepManager.isPreventingSleep ? "Deactivate Kawa" : "Activate Kawa"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleCaffeinate), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // About menu item
        let aboutItem = NSMenuItem(title: "About Kawa", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // Settings menu item
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit menu item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Show the menu
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func toggleCaffeinate() {
        sleepManager.toggle()
    }

    @objc private func openSettings() {
        settingsState.selectedTab = .general
        openSettingsWindow()
    }
    
    @objc private func openAbout() {
        settingsState.selectedTab = .about
        openSettingsWindow()
    }
    
    private func openSettingsWindow() {
        let environment = EnvironmentValues()
        environment.openSettings()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quit() {
        print("👋 Quitting Kawa")
        NSApp.terminate(nil)
    }
}
