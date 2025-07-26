//
//  EEGOverlayViewController.swift
//  EEG EQUIPMENT ASSIST
//
//  Created by Abhay Kadambi on 7/24/25.
//

import Foundation
import UIKit
import ARKit
import SceneKit

class EEGOverlayViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    var hasCalibrated = false
    var calibrationNode: SCNNode?
    var meshAnchors: [ARMeshAnchor] = []
    var instructionLabel: UILabel!
    var resetButton: UIButton!
    var scanProgressView: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView = ARSCNView(frame: view.bounds)
        view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        instructionLabel = UILabel()
        instructionLabel.text = "Walk around the person to scan their head..."
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(instructionLabel)

        scanProgressView = UIProgressView(progressViewStyle: .default)
        scanProgressView.progressTintColor = .green
        scanProgressView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(scanProgressView)

        resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset Calibration", for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        resetButton.layer.cornerRadius = 6
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetCalibration), for: .touchUpInside)
        sceneView.addSubview(resetButton)

        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: sceneView.safeAreaLayoutGuide.topAnchor, constant: 20),

            scanProgressView.leadingAnchor.constraint(equalTo: sceneView.leadingAnchor, constant: 20),
            scanProgressView.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor, constant: -20),
            scanProgressView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 10),

            resetButton.topAnchor.constraint(equalTo: scanProgressView.bottomAnchor, constant: 10),
            resetButton.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 180),
            resetButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravity
        config.sceneReconstruction = .meshWithClassification
        config.environmentTexturing = .automatic
        config.frameSemantics = .sceneDepth
        config.planeDetection = [.horizontal, .vertical]

        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let meshAnchor = anchor as? ARMeshAnchor {
            meshAnchors.append(meshAnchor)
            let progress = min(Float(meshAnchors.count) / 100.0, 1.0)
            DispatchQueue.main.async {
                self.scanProgressView.setProgress(progress, animated: true)
                if self.meshAnchors.count > 50 && !self.hasCalibrated {
                    self.instructionLabel.text = "Tap on the forehead to calibrate."
                }
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !hasCalibrated, let touch = touches.first else { return }

        let location = touch.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, types: [.featurePoint, .estimatedHorizontalPlane, .estimatedVerticalPlane])

        if let result = hitResults.first {
            let position = SCNVector3(
                result.worldTransform.columns.3.x,
                result.worldTransform.columns.3.y,
                result.worldTransform.columns.3.z
            )

            placeCalibrationDot(at: position)
            placeEEGDots(using: position)
            hasCalibrated = true
            instructionLabel.text = "EEG markers placed."
        }
    }

    @objc func resetCalibration() {
        hasCalibrated = false
        calibrationNode?.removeFromParentNode()
        calibrationNode = nil
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if let geometry = node.geometry as? SCNSphere, geometry.radius == 0.005 {
                node.removeFromParentNode()
            }
        }
        instructionLabel.text = "Tap on the forehead to calibrate."
    }

    func placeCalibrationDot(at position: SCNVector3) {
        let dot = makeDot(color: .green)
        dot.position = position
        sceneView.scene.rootNode.addChildNode(dot)
        calibrationNode = dot
    }

    func placeEEGDots(using base: SCNVector3) {
        let offsets: [(label: String, dx: Float, dy: Float, dz: Float)] = [
            ("Fp1", -0.03, 0.01,  0.00),
            ("Fp2",  0.03, 0.01,  0.00),
            ("Fz",   0.00, 0.02, -0.015),
            ("Cz",   0.00, 0.025, -0.045),
            ("Pz",   0.00, 0.025, -0.07),
            ("O1",  -0.025, 0.02, -0.09),
            ("O2",   0.025, 0.02, -0.09),
            ("Inion", 0.00, 0.015, -0.1)
        ]

        for (label, dx, dy, dz) in offsets {
            let target = SCNVector3(base.x + dx, base.y + dy, base.z + dz)
            if let projected = projectOntoMesh(from: target) {
                let dot = makeDot(color: .red)
                dot.position = projected

                let text = makeLabel(text: label)
                text.position = SCNVector3(projected.x, projected.y + 0.01, projected.z)

                sceneView.scene.rootNode.addChildNode(dot)
                sceneView.scene.rootNode.addChildNode(text)
            }
        }
    }

    func projectOntoMesh(from point: SCNVector3) -> SCNVector3? {
        var closestPoint: SCNVector3?
        var minDistance = Float.infinity

        for anchor in meshAnchors {
            let geometry = anchor.geometry
            let transform = anchor.transform

            let vertexBuffer = geometry.vertices
            let stride = vertexBuffer.stride
            let vertexCount = vertexBuffer.count

            let buffer = vertexBuffer.buffer
            let vertexData = buffer.contents().assumingMemoryBound(to: SIMD3<Float>.self)
            
            for i in 0..<vertexCount {
                let vertex = vertexData[i]
                let worldVertex = simd_mul(transform, SIMD4<Float>(vertex, 1.0))
                let v = SCNVector3(worldVertex.x, worldVertex.y, worldVertex.z)

                let distance = simd_distance(SIMD3<Float>(v), SIMD3<Float>(point))
                if distance < minDistance {
                    minDistance = distance
                    closestPoint = v
                }
            }
        }

        return closestPoint
    }

    func makeDot(color: UIColor) -> SCNNode {
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = color
        return SCNNode(geometry: sphere)
    }

    func makeLabel(text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.1)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.font = UIFont.systemFont(ofSize: 0.1)
        textGeometry.flatness = 0.1

        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.004, 0.004, 0.004)
        return textNode
    }
}
