import Foundation

// Manages the "Closed-Display Mode" (CDM), aka Clamshell Mode
enum ClosedDisplayManager {

    // Enables or disables closed-display mode
    // - Parameter enabled: true to prevent sleep when lid is closed, false to allow normal behavior
    // - Returns: true if operation succeeded, false otherwise
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        print("➡️ setClosedDisplayModeEnabled(\(enabled)) called")

        // Match the IOPMrootDomain service
        guard let matching = IOServiceMatching("IOPMrootDomain") else { return false }

        // Get the first matching service
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != 0 else { return false }

        // Open a connection to the root domain
        var connect: io_connect_t = 0
        let kr = IOServiceOpen(service, mach_task_self_, 0, &connect)
        IOObjectRelease(service)
        guard kr == KERN_SUCCESS else { return false }

        // Prepare input value (1 = enable CDM, 0 = disable)
        var input: UInt64 = enabled ? 1 : 0
        let selector: UInt32 = UInt32(kPMSetClamshellSleepState)

        // Call the kernel method to set clamshell sleep state
        let result = withUnsafePointer(to: &input) { inputPtr in
            IOConnectCallScalarMethod(connect, selector, inputPtr, 1, nil, nil)
        }

        // Close connection
        IOServiceClose(connect)

        return result == KERN_SUCCESS
    }
}
