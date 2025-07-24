//
//  CameraViewController.swift
//  EEG EQUIPMENT ASSIST
//
//  Created by Abhay Kadambi on 7/24/25.
//

import Foundation

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var faceBoxes: [CAShapeLayer] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    func setupCamera() {
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(output)

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest { [weak self] req, _ in
            DispatchQueue.main.async {
                self?.handleFaces(request: req)
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
        try? handler.perform([request])
    }

    func handleFaces(request: VNRequest) {
        faceBoxes.forEach { $0.removeFromSuperlayer() }
        faceBoxes.removeAll()

        guard let results = request.results as? [VNFaceObservation] else { return }

        for face in results {
            let box = createBox(for: face)
            view.layer.addSublayer(box)
            faceBoxes.append(box)
        }
    }

    func createBox(for face: VNFaceObservation) -> CAShapeLayer {
        let boundingBox = face.boundingBox
        let size = CGSize(width: boundingBox.width * view.frame.width,
                          height: boundingBox.height * view.frame.height)
        let origin = CGPoint(x: boundingBox.minX * view.frame.width,
                             y: (1 - boundingBox.maxY) * view.frame.height)

        let rect = CGRect(origin: origin, size: size)
        let box = CAShapeLayer()
        box.frame = rect
        box.borderColor = UIColor.red.cgColor
        box.borderWidth = 2
        return box
    }
}
