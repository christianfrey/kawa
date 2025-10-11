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
    private var cancellables = Set<AnyCancellable>()
    
    private let remainingTimeMenuItem = NSMenuItem()
    private var remainingTimeValueLabel: NSTextField?
    
    @Published private(set) var quickStartClickMode: QuickStartClickMode = .right

    private lazy var settingsWindowController = makeSettingsController()
    
    // MARK: - Initialization

    override init() {
        super.init()
        
        loadInitialPreferences()
        setupRemainingTimeItem()
        setupMenuBarItem()
        setupObservers()
    }
    
    // MARK: - Setup

    private func loadInitialPreferences() {
        quickStartClickMode = UserDefaults.standard.quickStartClickMode
        print("⚙️ Initial click mode: \(quickStartClickMode.displayName)")
    }

    private func makeSettingsController() -> SettingsWindowController {
        let panes: [any SettingsPane] = [
            createSettingsPane(
                identifier: "general",
                title: "General",
                icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General")!,
                content: { GeneralSettingsView() }
            ),
            createSettingsPane(
                identifier: "duration",
                title: "Duration",
                icon: NSImage(systemSymbolName: "clock", accessibilityDescription: "Duration")!,
                content: { DurationSettingsView() }
            ),
            createSettingsPane(
                identifier: "battery",
                title: "Battery",
                icon: NSImage(systemSymbolName: "battery.75", accessibilityDescription: "Battery")!,
                content: { BatterySettingsView() }
            ),
            createSettingsPane(
                identifier: "notifications",
                title: "Notifications",
                icon: NSImage(systemSymbolName: "bell.badge", accessibilityDescription: "Notifications")!,
                content: { NotificationsSettingsView() }
            ),
            createSettingsPane(
                identifier: "about",
                title: "About",
                icon: NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")!,
                content: { AboutSettingsView() }
            )
        ]
        
        return SettingsWindowController(panes: panes)
    }

    private func createSettingsPane<V: View>(
        identifier: String,
        title: String,
        icon: NSImage,
        @ViewBuilder content: () -> V
    ) -> any SettingsPane {
        let view = content()
            .frame(width: 500, alignment: .topLeading)
        
        let hostingController = SettingsPaneHostingController(
            identifier: identifier,
            title: title,
            icon: icon,
            content: { view }
        )
        
        return hostingController
    }

    
    private func setupRemainingTimeItem() {
        enum Constants {
            static let viewWidth: CGFloat = 200.0
            static let viewHeight: CGFloat = 42.0
            static let horizontalPadding: CGFloat = 13.0
            static let spacing: CGFloat = 4.0
            static let fontSize: CGFloat = 13.0
        }

        // Container view
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        // container.wantsLayer = true
        // container.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1).cgColor
        remainingTimeMenuItem.view = container
        remainingTimeMenuItem.isHidden = true

        // Title label
        let titleLabel = NSTextField(labelWithString: "Remaining time:")
        titleLabel.font = NSFont.menuFont(ofSize: Constants.fontSize)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .left
        // titleLabel.drawsBackground = true
        // titleLabel.backgroundColor = .systemRed.withAlphaComponent(0.3)

        // Value label
        let valueLabel = NSTextField(labelWithString: "")
        valueLabel.font = NSFont.menuFont(ofSize: Constants.fontSize)
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.alignment = .left
        valueLabel.identifier = NSUserInterfaceItemIdentifier("RemainingTimeValue")
        // valueLabel.drawsBackground = true
        // valueLabel.backgroundColor = .systemGreen.withAlphaComponent(0.3)
        self.remainingTimeValueLabel = valueLabel

        // Stack view vertical
        let stackView = NSStackView(views: [titleLabel, valueLabel])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = Constants.spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stackView)

        // Constraints
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: Constants.viewWidth),
            container.heightAnchor.constraint(equalToConstant: Constants.viewHeight),

            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Constants.horizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Constants.horizontalPadding),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
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
        observeRemainingTimeChanges()
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
    
    private func observeRemainingTimeChanges() {
        sleepManager.$remainingTimeFormatted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remainingTime in
                self?.updateRemainingTimeMenuItem(with: remainingTime)
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
    
    private func updateRemainingTimeMenuItem(with remainingTime: String) {
        let shouldShow = !remainingTime.isEmpty && sleepManager.isPreventingSleep
        remainingTimeMenuItem.isHidden = !shouldShow
        
        if shouldShow {
            remainingTimeValueLabel?.stringValue = remainingTime
        }
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
        
        // Remaining time block
        if !remainingTimeMenuItem.isHidden {
            menu.addItem(remainingTimeMenuItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Toggle
        let toggleTitle = sleepManager.isPreventingSleep ? "Deactivate Kawa" : "Activate Kawa"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleCaffeinate), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // About
        let aboutItem = NSMenuItem(title: "About Kawa", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    // MARK: - Menu Actions
    @objc private func toggleCaffeinate() {
        sleepManager.toggle()
    }
    
    @objc private func openSettings() {
        settingsWindowController.show(pane: "general")
    }
    
    @objc private func openAbout() {
        settingsWindowController.show(pane: "about")
    }

    @objc private func quit() {
        print("👋 Quitting Kawa")
        NSApp.terminate(nil)
    }
}
