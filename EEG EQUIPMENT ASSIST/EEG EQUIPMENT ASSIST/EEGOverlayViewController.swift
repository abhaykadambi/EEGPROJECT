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
    var placedDots: [SCNNode] = []
    var hasCalibrated = false
    var calibrationNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView = ARSCNView(frame: view.bounds)
        view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .meshWithClassification
        config.environmentTexturing = .automatic
        config.frameSemantics = .sceneDepth
        config.planeDetection = [.horizontal, .vertical]

        sceneView.session.run(config)
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else { return }
        
        if !hasCalibrated {
            placeCalibrationDot(on: meshAnchor, with: node)
        } else {
            placeEEGDots(relativeTo: meshAnchor, with: node)
        }
    }

    func placeCalibrationDot(on meshAnchor: ARMeshAnchor, with node: SCNNode) {
        let headCenter = meshAnchor.center
        let calDot = makeDot(color: .green)
        calDot.position = SCNVector3(headCenter.x, headCenter.y + 0.05, headCenter.z + 0.05)
        node.addChildNode(calDot)
        calibrationNode = calDot
        hasCalibrated = true
    }

    func placeEEGDots(relativeTo meshAnchor: ARMeshAnchor, with node: SCNNode) {
        guard let reference = calibrationNode else { return }

        let base = reference.position

        let positions: [(String, SCNVector3)] = [
            ("Fp1", SCNVector3(base.x - 0.03, base.y + 0.01, base.z)),
            ("Fp2", SCNVector3(base.x + 0.03, base.y + 0.01, base.z)),
            ("Fz",  SCNVector3(base.x, base.y + 0.02, base.z - 0.015)),
            ("Cz",  SCNVector3(base.x, base.y + 0.025, base.z - 0.045)),
            ("Pz",  SCNVector3(base.x, base.y + 0.025, base.z - 0.07)),
            ("O1",  SCNVector3(base.x - 0.025, base.y + 0.02, base.z - 0.09)),
            ("O2",  SCNVector3(base.x + 0.025, base.y + 0.02, base.z - 0.09)),
            ("Inion", SCNVector3(base.x, base.y + 0.015, base.z - 0.1))
        ]

        for (label, position) in positions {
            let dot = makeDot(color: .red)
            dot.position = position
            let labelNode = makeLabel(text: label)
            labelNode.position = SCNVector3(position.x, position.y + 0.01, position.z)
            node.addChildNode(dot)
            node.addChildNode(labelNode)
            placedDots.append(dot)
        }
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
        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.004, 0.004, 0.004)
        return textNode
    }
}
