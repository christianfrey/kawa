import Foundation

// Manages the "Closed-Display Mode" (CDM)
enum ClosedDisplayManager {

    // Enables or disables closed-display mode
    // - Parameter enabled: true to prevent sleep when lid is closed, false to allow normal behavior
    // - Returns: true if operation succeeded, false otherwise
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        print("➡️ setClosedDisplayModeEnabled(\(enabled)) called")
        
        // Match the IOPMrootDomain service
        guard let matching = IOServiceMatching("IOPMrootDomain") else {
            print("❌ IOServiceMatching returned nil")
            return false
        }
        
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != 0 else {
            print("❌ IOServiceGetMatchingService failed (no service found)")
            return false
        }
        print("✅ Got IOPMrootDomain service: \(service)")
        
        // Open a connection to the root domain
        var connect: io_connect_t = 0
        let kr = IOServiceOpen(service, mach_task_self_, 0, &connect)
        IOObjectRelease(service)
        guard kr == KERN_SUCCESS else {
            print("❌ IOServiceOpen failed: \(String(format: "0x%08x", kr))")
            return false
        }
        print("✅ IOServiceOpen succeeded, connect=\(connect)")
        
        // Prepare input and selector
        var input: UInt64 = enabled ? 1 : 0
        let selector: UInt32 = UInt32(kPMSetClamshellSleepState)
        
        // Call the method to set clamshell sleep state
        let callResult = withUnsafePointer(to: &input) { inputPtr in
            IOConnectCallScalarMethod(connect, selector, inputPtr, 1, nil, nil)
        }
        
        if callResult != KERN_SUCCESS {
            print("❌ IOConnectCallScalarMethod failed: \(String(format: "0x%08x", callResult))")
            IOServiceClose(connect)
            return false
        }
        
        print("✅ IOConnectCallScalarMethod succeeded, closed-display mode = \(enabled)")
        IOServiceClose(connect)
        print("🔻 IOServiceClose done")
        return true
    }
}
