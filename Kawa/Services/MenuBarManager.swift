import SwiftUI
import AppKit // MenuBarExtra does not support right-click handling, so use NSStatusBar
import Combine

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
        
        switch event.type {
        case .leftMouseUp:
            // Left click - show menu
            print("🖱️ Left click - showing menu")
            showMenu()
        case .rightMouseUp:
            // Right click - toggle Kawa
            print("🖱️ Right click - toggling Kawa")
            sleepManager.toggle()
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
