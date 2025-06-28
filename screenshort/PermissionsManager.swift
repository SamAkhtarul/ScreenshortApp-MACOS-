
import AppKit

class PermissionsManager {

    func checkPermissions() {
        guard !hasScreenRecordingPermission() else { return }
        requestScreenRecordingPermission()
    }

    private func hasScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }

    private func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }
}
