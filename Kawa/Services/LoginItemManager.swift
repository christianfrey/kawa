import Foundation
import ServiceManagement
import Combine

@MainActor
class LoginItemManager: ObservableObject {
    static let shared = LoginItemManager()
    
    @Published var isEnabled: Bool = false
    
    private init() {
        updateStatus()
    }
    
    private func updateStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    func enable() throws {
        guard SMAppService.mainApp.status != .enabled else { return }
        
        try SMAppService.mainApp.register()
        updateStatus()
    }
    
    func disable() throws {
        guard SMAppService.mainApp.status == .enabled else { return }
        
        try SMAppService.mainApp.unregister()
        updateStatus()
    }
    
    func toggle() {
        do {
            if isEnabled {
                try disable()
            } else {
                try enable()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }
}
