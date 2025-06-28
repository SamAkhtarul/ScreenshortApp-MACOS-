import SwiftUI

@main
struct screenshortApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The app will be controlled by the menu bar item, so no main window is needed.
        // A settings window can be opened from the menu bar.
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    var hotkeyManager: HotkeyManager?
    var screenshotManager: ScreenshotManager?
    var permissionsManager: PermissionsManager?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        permissionsManager = PermissionsManager()
        screenshotManager = ScreenshotManager()
        
        menuBarManager = MenuBarManager(screenshotManager: screenshotManager!)
        hotkeyManager = HotkeyManager(screenshotManager: screenshotManager!)

        permissionsManager?.checkPermissions()
    }
}