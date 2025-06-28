import AppKit
import CoreGraphics
import SwiftUI
import ScreenCaptureKit

class ScreenshotManager: NSObject, SCStreamOutput {

    private var stream: SCStream?
    private var continuation: CheckedContinuation<NSImage?, Error>?

    override init() {
        super.init()
    }

    func captureFullScreen() {
        Task {
            do {
                let content = try await SCShareableContent.current
                guard let display = content.displays.first else {
                    print("No display found.")
                    return
                }
                let image = try await capture(content: .display(display), rect: display.frame)
                if let img = image { self.save(image: img) }
            } catch {
                print("Error capturing full screen: \(error.localizedDescription)")
            }
        }
    }

    func captureWindow() {
        NSApp.windows.forEach { $0.orderOut(nil) }

        let panel = NSPanel(contentRect: NSScreen.main?.frame ?? .zero,
                            styleMask: [.borderless],
                            backing: .buffered,
                            defer: true)
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = false
        panel.makeKeyAndOrderFront(nil)

        let windowSelectionView = WindowSelectionView { selectedWindowRect in
            Task {
                if let rect = selectedWindowRect {
                    do {
                        let content = try await SCShareableContent.current
                        // Find the window that matches the selected rect
                        guard let window = content.windows.first(where: { $0.frame == rect }) else {
                            print("Could not find selected window.")
                            return
                        }
                        let image = try await self.capture(content: .window(window), rect: rect)
                        if let img = image { self.save(image: img) }
                    } catch {
                        print("Error capturing window: \(error.localizedDescription)")
                    }
                }
                panel.close()
                NSApp.windows.forEach { $0.makeKeyAndOrderFront(nil) }
            }
        }
        panel.contentView = NSHostingView(rootView: windowSelectionView)
    }

    func captureArea() {
        NSApp.windows.forEach { $0.orderOut(nil) }

        let panel = NSPanel(contentRect: NSScreen.main?.frame ?? .zero,
                            styleMask: [.borderless],
                            backing: .buffered,
                            defer: true)
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = false
        panel.makeKeyAndOrderFront(nil)

        let selectionView = SelectionView(onSelectionComplete: { selectedRect in
            Task {
                if let rect = selectedRect {
                    do {
                        let content = try await SCShareableContent.current
                        guard let display = content.displays.first else {
                            print("No display found for area capture.")
                            return
                        }
                        let image = try await self.capture(content: .display(display), rect: rect)
                        if let img = image { self.save(image: img) }
                    } catch {
                        print("Error capturing area: \(error.localizedDescription)")
                    }
                }
                panel.close()
                NSApp.windows.forEach { $0.makeKeyAndOrderFront(nil) }
            }
        })

        panel.contentView = NSHostingView(rootView: selectionView)
    }

    private func capture(content: SCContentEntity, rect: CGRect) async throws -> NSImage? {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            guard CGPreflightScreenCaptureAccess() else {
                continuation.resume(throwing: NSError(domain: "ScreenshotApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Screen recording permission not granted."]))
                return
            }

            let filter: SCContentFilter
            let streamConfig = SCStreamConfiguration()

            switch content {
            case .display(let display):
                filter = SCContentFilter(display: display, excludingWindows: [])
                streamConfig.width = Int(rect.width)
                streamConfig.height = Int(rect.height)
                streamConfig.sourceRect = rect
            case .window(let window):
                filter = SCContentFilter(desktopIndependentWindow: window)
                streamConfig.width = Int(window.frame.width)
                streamConfig.height = Int(window.frame.height)
                streamConfig.sourceRect = .zero // Capture the whole window
            default:
                continuation.resume(throwing: NSError(domain: "ScreenshotApp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported content type."]))
                return
            }

            streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            streamConfig.queueDepth = 5
            streamConfig.capturesAudio = false

            self.stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
            do {
                try self.stream?.addStreamOutput(self, type: .screen, sampleBufferDelegate: nil)
            } catch {
                continuation.resume(throwing: error)
                self.continuation = nil
                return
            }

            self.stream?.startCapture { error in
                if let error = error {
                    self.continuation?.resume(throwing: error)
                    self.continuation = nil
                }
            }
        }
    }

    // MARK: - SCStreamOutput Delegate
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        guard sampleBuffer.isValid else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let nsImage = NSImage(ciImage: ciImage)

        self.continuation?.resume(returning: nsImage)
        self.continuation = nil

        stream.stopCapture { error in
            if let error = error {
                print("Error stopping stream: \(error.localizedDescription)")
            }
        }
    }

    private func save(image: NSImage) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg] // Use allowedContentTypes
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "Screenshot-\(Date().description).png" // Default to PNG

        savePanel.begin { [weak self] response in // Capture self explicitly
            guard let self = self else { return }
            if response == .OK {
                guard let url = savePanel.url else { return }
                let fileExtension = url.pathExtension.lowercased()

                guard let imageData = image.tiffRepresentation else {
                    print("Could not get TIFF representation.")
                    return
                }

                let bitmapImageRep = NSBitmapImageRep(data: imageData)
                var finalData: Data?

                if fileExtension == "png" {
                    finalData = bitmapImageRep?.representation(using: .png, properties: [:])
                } else if fileExtension == "jpg" || fileExtension == "jpeg" {
                    finalData = bitmapImageRep?.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                }

                do {
                    if let data = finalData {
                        try data.write(to: url)
                        print("Screenshot saved to: \(url.path)")
                        self.showPreview(image: image, at: url) // Explicit self
                    }
                } catch {
                    print("Error saving image: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showPreview(image: NSImage, at url: URL) {
        let alert = NSAlert()
        alert.messageText = "Screenshot Saved!"
        alert.informativeText = "Your screenshot has been saved to \(url.lastPathComponent)."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "OK")

        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 200, height: 150))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        alert.accessoryView = imageView

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(url)
        }
    }
}