import SwiftUI

// MARK: - Settings Pane Protocol
protocol SettingsPane: NSViewController {
    var paneIdentifier: String { get }
    var paneTitle: String { get }
    var toolbarItemIcon: NSImage { get }
}

// MARK: - Settings Window Controller
final class SettingsWindowController: NSWindowController {
    private let panes: [SettingsPane]
    private var toolbar: NSToolbar?
    private var currentPaneIdentifier: String?
    private weak var currentTabView: NSView?
    
    init(panes: [SettingsPane]) {
        self.panes = panes
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.toolbarStyle = .preference
        
        super.init(window: window)
        
        setupToolbar()
        
        // Show first pane by default
        if let firstPane = panes.first {
            showPane(identifier: firstPane.paneIdentifier)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Toolbar Setup
    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: NSToolbar.Identifier("SettingsToolbar"))
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconAndLabel
        // toolbar.showsBaselineSeparator = true
        
        self.toolbar = toolbar
        window?.toolbar = toolbar
        
        // Set default selected item
        if let firstPane = panes.first {
            toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(firstPane.paneIdentifier)
        }
    }
    
    // MARK: - Pane Switching
    func showPane(identifier: String) {
        guard let pane = panes.first(where: { $0.paneIdentifier == identifier }) else {
            return
        }

        // Update window title
        window?.title = pane.paneTitle
        
        // Update toolbar selection
        toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(identifier)
        
        // If same pane, do nothing
        if currentPaneIdentifier == identifier {
            return
        }
        
        currentPaneIdentifier = identifier
        
        // Get the new pane's view
        let newView = pane.view
        
        // Calculate the new window frame
        let newWindowFrame = window?.frameRect(forContentRect: NSRect(origin: .zero, size: newView.fittingSize)) ?? .zero
        var frame = window?.frame ?? .zero
        frame.origin.y += frame.height - newWindowFrame.height
        frame.size = newWindowFrame.size

        // Keep track of the current tab view
        self.currentTabView = newView

        // MARK: - Pane Animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            // Animate window resize
            window?.animator().setFrame(frame, display: true)
            
            // Crossfade transition
            guard let contentView = window?.contentView else { return }
            let oldView = contentView.subviews.first
            
            // Prepare new view
            newView.alphaValue = 0.0
            newView.frame = contentView.bounds
            newView.autoresizingMask = [.width, .height]
            contentView.addSubview(newView)
            
            // Animate fade
            newView.animator().alphaValue = 1.0
            oldView?.animator().alphaValue = 0.0
        }, completionHandler: { [weak self, weak newView] in
            guard
                let self = self,
                let contentView = self.window?.contentView,
                let newView = newView
            else { return }

            // Only clean up if this is still the active tab
            guard self.currentTabView === newView else { return }

            // Remove all old views except the current one
            contentView.subviews
                .filter { $0 != newView }
                .forEach { $0.removeFromSuperview() }
        })
    }
    
    // MARK: - Show Window
    func show(pane identifier: String? = nil) {
        if let identifier = identifier {
            showPane(identifier: identifier)
        }
        
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Toolbar Delegate
extension SettingsWindowController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let pane = panes.first(where: { $0.paneIdentifier == itemIdentifier.rawValue }) else {
            return nil
        }
        
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = pane.paneTitle
        item.image = pane.toolbarItemIcon
        item.target = self
        item.action = #selector(toolbarItemClicked(_:))
        
        return item
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return panes.map { NSToolbarItem.Identifier($0.paneIdentifier) }
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return panes.map { NSToolbarItem.Identifier($0.paneIdentifier) }
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return panes.map { NSToolbarItem.Identifier($0.paneIdentifier) }
    }
    
    @objc private func toolbarItemClicked(_ sender: NSToolbarItem) {
        showPane(identifier: sender.itemIdentifier.rawValue)
    }
}

// MARK: - SwiftUI Hosting Controller for Settings Pane
final class SettingsPaneHostingController<Content: View>: NSHostingController<Content>, SettingsPane {
    let paneIdentifier: String
    let paneTitle: String
    let toolbarItemIcon: NSImage
    
    init(identifier: String, title: String, icon: NSImage, @ViewBuilder content: () -> Content) {
        self.paneIdentifier = identifier
        self.paneTitle = title
        self.toolbarItemIcon = icon
        
        super.init(rootView: content())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}