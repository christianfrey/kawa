import SwiftUI
import AppKit // MenuBarExtra does not support right-click handling, so use NSStatusBar
import Combine

// MARK: - Quick Start Click Mode

enum QuickStartClickMode: String, CaseIterable {
    case left = "left"
    case right = "right"
    
    var displayName: String {
        switch self {
        case .left: return "Left Click"
        case .right: return "Right Click"
        }
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    private enum Keys {
        static let quickStartClickMode = "quickStartClickMode"
    }
    
    var quickStartClickMode: QuickStartClickMode {
        get {
            guard let value = string(forKey: Keys.quickStartClickMode),
                  let mode = QuickStartClickMode(rawValue: value) else {
                return .right // Default mode
            }
            return mode
        }
        set {
            set(newValue.rawValue, forKey: Keys.quickStartClickMode)
        }
    }
}

// MARK: - Menu Bar Manager

@MainActor
final class MenuBarManager: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private let sleepManager = SleepPreventionManager.shared
    private let settingsState: SettingsState
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var quickStartClickMode: QuickStartClickMode = .right
    
    // MARK: - Initialization
    
    init(settingsState: SettingsState) {
        self.settingsState = settingsState
        super.init()
        
        loadInitialPreferences()
        setupMenuBarItem()
        setupObservers()
    }
    
    // MARK: - Setup Methods
    
    private func loadInitialPreferences() {
        quickStartClickMode = UserDefaults.standard.quickStartClickMode
        print("⚙️ Initial click mode: \(quickStartClickMode.displayName)")
    }
    
    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusItem?.button else { return }
        
        updateIcon()
        button.action = #selector(statusItemClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    private func setupObservers() {
        observeSleepStateChanges()
        observeUserDefaultsChanges()
    }
    
    private func observeSleepStateChanges() {
        sleepManager.$isPreventingSleep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)
    }
    
    private func observeUserDefaultsChanges() {
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .compactMap { _ in UserDefaults.standard.quickStartClickMode }
            .removeDuplicates()
            .sink { [weak self] newMode in
                self?.handleClickModeChange(newMode)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Update Methods
    
    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        
        let iconName = sleepManager.isPreventingSleep ? "CoffeeCupHot" : "CoffeeBean"
        
        guard let image = NSImage(named: iconName) else { return }
        image.isTemplate = true
        button.image = image
    }
    
    private func handleClickModeChange(_ newMode: QuickStartClickMode) {
        guard quickStartClickMode != newMode else { return }
        
        quickStartClickMode = newMode
        print("⚙️ Click mode changed to: \(newMode.displayName)")
    }
    
    // MARK: - Click Handler
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        let isQuickAction = isQuickActionEvent(event)
        
        if isQuickAction {
            print("🖱️ Quick action triggered → toggle Kawa")
            sleepManager.toggle()
        } else {
            print("🖱️ Menu action triggered → show menu")
            showMenu()
        }
    }
    
    private func isQuickActionEvent(_ event: NSEvent) -> Bool {
        switch event.type {
        case .leftMouseUp:
            return quickStartClickMode == .left
        case .rightMouseUp:
            return quickStartClickMode == .right
        default:
            return false
        }
    }
    
    // MARK: - Menu Building
    
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
    
    // MARK: - Menu Actions
    
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
        EnvironmentValues().openSettings()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quit() {
        print("👋 Quitting Kawa")
        NSApp.terminate(nil)
    }
}
