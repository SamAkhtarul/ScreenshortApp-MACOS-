import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "camera.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            Text("Screenshort App")
                .font(.title)
            Text("This app runs in the menu bar.")
                .font(.subheadline)
            Text("Click the camera icon in your menu bar to take a screenshot.")
                .font(.caption)
                .padding(.top, 10)
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }
}

#Preview {
    ContentView()
}