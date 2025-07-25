import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        EEGOverlayView() // Replaces CameraView or FaceARView
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
