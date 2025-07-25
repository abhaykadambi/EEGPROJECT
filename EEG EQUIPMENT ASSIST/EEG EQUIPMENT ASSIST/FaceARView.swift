//
//  FaceARView.swift
//  EEG EQUIPMENT ASSIST
//
//  Created by Abhay Kadambi on 7/24/25.
//

import Foundation
import SwiftUI
import ARKit
import SceneKit

struct FaceARView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> FaceARViewController {
        return FaceARViewController()
    }

    func updateUIViewController(_ uiViewController: FaceARViewController, context: Context) {}
}

