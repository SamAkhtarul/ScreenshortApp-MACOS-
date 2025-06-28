
import AppKit

class MenuBarManager {
    private var statusItem: NSStatusItem
    private var screenshotManager: ScreenshotManager

    init(screenshotManager: ScreenshotManager) {
        self.screenshotManager = screenshotManager
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera", accessibilityDescription: "Screenshot App")
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        let fullScreenItem = NSMenuItem(title: "Capture Full Screen", action: #selector(captureFullScreen), keyEquivalent: "3")
        fullScreenItem.target = self
        menu.addItem(fullScreenItem)

        let windowItem = NSMenuItem(title: "Capture Window", action: #selector(captureWindow), keyEquivalent: "4")
        windowItem.target = self
        menu.addItem(windowItem)

        let areaItem = NSMenuItem(title: "Capture Area", action: #selector(captureArea), keyEquivalent: "5")
        areaItem.target = self
        menu.addItem(areaItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func captureFullScreen() {
        screenshotManager.captureFullScreen()
    }

    @objc private func captureWindow() {
        screenshotManager.captureWindow()
    }

    @objc private func captureArea() {
        screenshotManager.captureArea()
    }
}
