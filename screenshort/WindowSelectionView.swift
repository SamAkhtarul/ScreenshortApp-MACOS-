import AppKit
import SwiftUI

// Helper view for window selection
struct WindowSelectionView: View {
    var onWindowSelected: (CGRect?) async -> Void
    @State private var windowRects: [CGRect] = []
    @State private var selectedWindowRect: CGRect?

    var body: some View {
        ZStack {
            Color.black.opacity(0.001) // Invisible background to capture clicks
                .contentShape(Rectangle()) // Make the whole area tappable
                .onTapGesture {
                    Task { await onWindowSelected(nil) } // Call async function
                }

            ForEach(windowRects.indices, id: \.self) { index in
                let rect = windowRects[index]
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .border(Color.blue, width: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .onTapGesture {
                        selectedWindowRect = rect
                        Task { await onWindowSelected(rect) } // Call async function
                    }
            }
        }
        .onAppear(perform: loadWindows)
    }

    private func loadWindows() {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as NSArray? as? [[String: AnyObject]]

        guard let list = windowList else { return }

        windowRects = list.compactMap { entry in
            let bounds = entry[kCGWindowBounds as String] as? [String: CGFloat]
            let ownerName = entry[kCGWindowOwnerName as String] as? String
            let isAppWindow = entry[kCGWindowIsOnscreen as String] as? Bool ?? false
            let layer = entry[kCGWindowLayer as String] as? Int ?? 0

            // Filter out background windows, desktop elements, and our own app's windows
            if let boundsDict = bounds,
               let x = boundsDict["X"],
               let y = boundsDict["Y"],
               let width = boundsDict["Width"],
               let height = boundsDict["Height"],
               isAppWindow,
               layer == 0, // Only capture regular application windows
               ownerName != Bundle.main.infoDictionary?["CFBundleName"] as? String { // Exclude self
                return CGRect(x: x, y: y, width: width, height: height)
            }
            return nil
        }
    }
}