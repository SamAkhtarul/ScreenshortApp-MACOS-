
import SwiftUI

struct SelectionView: View {
    var onSelectionComplete: (CGRect?) async -> Void
    @State private var startPoint: CGPoint?
    @State private var endPoint: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                if let startPoint = startPoint, let endPoint = endPoint {
                    let rect = CGRect(x: min(startPoint.x, endPoint.x),
                                      y: min(startPoint.y, endPoint.y),
                                      width: abs(startPoint.x - endPoint.x),
                                      height: abs(startPoint.y - endPoint.y))
                    path.addRect(rect)
                }
            }
            .stroke(Color.blue, lineWidth: 2)
            .background(Color.black.opacity(0.3))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if self.startPoint == nil {
                            self.startPoint = value.location
                        }
                        self.endPoint = value.location
                    }
                    .onEnded { value in
                        Task { // Use Task to call async onSelectionComplete
                            if let startPoint = self.startPoint, let endPoint = self.endPoint {
                                let selectedRect = CGRect(x: min(startPoint.x, endPoint.x),
                                                            y: min(startPoint.y, endPoint.y),
                                                            width: abs(startPoint.x - endPoint.x),
                                                            height: abs(startPoint.y - endPoint.y))
                                await self.onSelectionComplete(selectedRect)
                            } else {
                                await self.onSelectionComplete(nil)
                            }
                        }
                    }
            )
        }
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
