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
        
        self.toolbar = toolbar
        window?.toolbar = toolbar
        
        if let firstPane = panes.first {
            toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(firstPane.paneIdentifier)
        }
    }
    
    // MARK: - Pane Switching
    func showPane(identifier: String) {
        print("showPane called - identifier=\(identifier)")
        guard let pane = panes.first(where: { $0.paneIdentifier == identifier }),
            let window = window else {
            return
        }

        // Skip if same pane
        if currentPaneIdentifier == identifier { return }

        currentPaneIdentifier = identifier

        // Determine if this is the first display
        let isFirstDisplay = !window.isVisible

        // Update title & toolbar
        window.title = pane.paneTitle
        toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(identifier)

        // New view setup
        let newView = pane.view
        let newSize = newView.fittingSize
        let newFrame = window.frameRect(forContentRect: NSRect(origin: .zero, size: newSize))

        // Prepare window frame
        var frame = window.frame
        frame.origin.y += frame.height - newFrame.height
        frame.size = newFrame.size

        // Apply size immediately if first display
        if isFirstDisplay {
            window.setFrame(frame, display: true)
            window.layoutIfNeeded()
        }

        guard let contentView = window.contentView else { return }
        let oldView = contentView.subviews.first

        // Prepare new view
        newView.alphaValue = isFirstDisplay ? 1.0 : 0.0
        newView.autoresizingMask = [.width, .minYMargin]

        // Position view at top (approx toolbar offset)
        let yOffset: CGFloat = 45
        newView.frame = NSRect(
            x: 0,
            y: contentView.bounds.height - newFrame.height + yOffset,
            width: newFrame.width,
            height: newFrame.height
        )
        contentView.addSubview(newView)
        currentTabView = newView

        // Skip animation if first display
        guard !isFirstDisplay else {
            oldView?.removeFromSuperview()
            return
        }

        // Animate transition
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            // Animate window resize
            window.animator().setFrame(frame, display: true)

            // Animate fade
            newView.animator().alphaValue = 1.0
            oldView?.animator().alphaValue = 0.0
        }, completionHandler: { [weak self, weak newView] in
            guard
                let self,
                let newView,
                let contentView = self.window?.contentView
            else { return }

            // Keep only the active pane
            guard self.currentTabView === newView else { return }
            contentView.subviews
                .filter { $0 != newView }
                .forEach { $0.removeFromSuperview() }
        })
    }
    
    // MARK: - Show Window
    func show(pane identifier: String? = nil) {
        print("show called - identifier=\(String(describing: identifier))")
        if let identifier = identifier {
            print("showPane will be called - identifier \(identifier)")
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
