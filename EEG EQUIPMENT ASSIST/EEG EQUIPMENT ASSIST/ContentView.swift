//
//  ContentView.swift
//  EEG EQUIPMENT ASSIST
//
//  Created by Abhay Kadambi on 7/23/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        CameraView()
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
