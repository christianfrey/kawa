import SwiftUI
import Combine

class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    var service = CaffeinateService()
    private var cancellable: AnyCancellable?
    
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
        
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }

    private func createCoffeeIcon(filled: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        if filled {
            // Active state - filled coffee cup
            NSColor.controlAccentColor.setFill()
            NSColor.controlAccentColor.setStroke()
        } else {
            // Inactive state - empty coffee cup
            NSColor.clear.setFill()
            NSColor.labelColor.setStroke()
        }
        
        // Draw coffee cup
        let cupRect = NSRect(x: 2, y: 2, width: 10, height: 12)
        let cupPath = NSBezierPath(roundedRect: cupRect, xRadius: 1, yRadius: 1)
        cupPath.lineWidth = 1.5
        cupPath.fill()
        cupPath.stroke()
        
        // Draw handle
        NSColor.labelColor.setStroke()
        let handlePath = NSBezierPath()
        handlePath.move(to: NSPoint(x: 12, y: 10))
        handlePath.appendArc(
            withCenter: NSPoint(x: 14, y: 8),
            radius: 2,
            startAngle: 90,
            endAngle: 270,
            clockwise: true
        )
        handlePath.lineWidth = 1.5
        handlePath.stroke()
        
        // Draw steam if active
        if filled {
            NSColor.secondaryLabelColor.setStroke()
            for i in 0..<3 {
                let x = 4 + CGFloat(i * 2)
                let steamPath = NSBezierPath()
                steamPath.move(to: NSPoint(x: x, y: 15))
                steamPath.curve(
                    to: NSPoint(x: x + 0.5, y: 17),
                    controlPoint1: NSPoint(x: x - 0.3, y: 15.5),
                    controlPoint2: NSPoint(x: x + 0.3, y: 16.5)
                )
                steamPath.lineWidth = 1
                steamPath.stroke()
            }
        }
        
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
    
    private func updateIcon(isActive: Bool) {
        guard let button = statusItem?.button else { return }
        
        let icon = createCoffeeIcon(filled: isActive)
        button.image = icon
        
//        // Tests : Using SF Symbols, adapts to light/dark mode automatically
//        let symbolName = isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
//        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Kawa Icon")
//        button.image = image
        
        // Update tooltip
        button.toolTip = isActive ? "Kawa active - Mac awake ☕" : "Kawa inactive - Click to activate ☕"
        
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
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Kawa"
        alert.informativeText = """
        Version 1.0
        
        A small app to keep your Mac awake.
        Uses macOS caffeinate command.
        
        Click the icon to toggle on/off.
        """
        alert.alertStyle = .informational
        if let icon = NSApp.applicationIconImage {
            alert.icon = icon
        }
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        print("👋 Quitting Kawa")
        NSApplication.shared.terminate(nil)
    }
}
