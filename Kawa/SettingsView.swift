import SwiftUI

struct SettingsView: View {
    @StateObject private var loginItemManager = LoginItemManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Kawa Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Section General
            GroupBox("General") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch at Login", isOn: Binding(
                        get: { loginItemManager.isEnabled },
                        set: { _ in loginItemManager.toggle() }
                    ))
                    .help("Launch Kawa automatically when your Mac starts up")
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
        .background(Color(.controlBackgroundColor))
    }
}

// Window controller for managing settings window
class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Settings"
        window.center()
        window.isReleasedWhenClosed = false
        
        // SwiftUI configuration
        let hostingController = NSHostingController(rootView: SettingsView())
        window.contentViewController = hostingController
        
        self.init(window: window)
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}