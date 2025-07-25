import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        FaceARView() // Replaces CameraView with AR-based EEG marker view
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
