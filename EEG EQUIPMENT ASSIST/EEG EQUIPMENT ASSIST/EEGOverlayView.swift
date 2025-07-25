//
//  EEGOverlayView.swift
//  EEG EQUIPMENT ASSIST
//
//  Created by Abhay Kadambi on 7/24/25.
//

import Foundation
import SwiftUI

struct EEGOverlayView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> EEGOverlayViewController {
        EEGOverlayViewController()
    }

    func updateUIViewController(_ uiViewController: EEGOverlayViewController, context: Context) {}
}
