import AppKit

class HotkeyManager {
    private var screenshotManager: ScreenshotManager
    private var fullScreenHotkeyMonitor: Any?
    private var areaSelectionHotkeyMonitor: Any?

    init(screenshotManager: ScreenshotManager) {
        self.screenshotManager = screenshotManager
        registerHotkeys()
    }

    private func registerHotkeys() {
        // Check for accessibility permissions first
        let trusted = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
        if !trusted {
            print("Accessibility permissions not granted. Hotkeys will not work.")
            // You might want to show an alert to the user here.
            return
        }

        // Cmd+Shift+3 for Full Screen
        fullScreenHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 20 { // 20 is the keycode for '3'
                self.screenshotManager.captureFullScreen()
            }
        }

        // Cmd+Shift+4 for Area Selection
        areaSelectionHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 21 { // 21 is the keycode for '4'
                self.screenshotManager.captureArea()
            }
        }
    }

    deinit {
        if let monitor = fullScreenHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = areaSelectionHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}