//
//  CameraView.swift
//  EEG EQUIPMENT ASSIST
//
//  Created by Abhay Kadambi on 7/24/25.
//

import Foundation

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

