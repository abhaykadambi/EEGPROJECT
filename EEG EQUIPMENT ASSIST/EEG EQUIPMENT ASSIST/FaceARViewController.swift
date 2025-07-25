//
//  FaceARViewController.swift
//  EEG EQUIPMENT ASSIST
//
//  Created by Abhay Kadambi on 7/24/25.
//

import Foundation
import UIKit
import ARKit
import SceneKit

class FaceARViewController: UIViewController, ARSCNViewDelegate {
    var sceneView = ARSCNView()

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.frame = view.bounds
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)

        let config = ARFaceTrackingConfiguration()
        sceneView.session.run(config, options: [])
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return nil }

        let faceNode = SCNNode()
        let scalpPositions = estimated1020Positions(from: faceAnchor)

        for position in scalpPositions {
            let dot = makeDotNode()
            dot.position = position
            faceNode.addChildNode(dot)
        }

        return faceNode
    }

    func makeDotNode() -> SCNNode {
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.red
        return SCNNode(geometry: sphere)
    }

    func estimated1020Positions(from faceAnchor: ARFaceAnchor) -> [SCNVector3] {
        let headTransform = faceAnchor.transform

        func offset(_ x: Float, _ y: Float, _ z: Float) -> SCNVector3 {
            let point = SIMD4<Float>(x, y, z, 1)
            let transformed = simd_mul(headTransform, point)
            return SCNVector3(transformed.x, transformed.y, transformed.z)
        }

        return [
            offset(-0.03,  0.08, 0.05), // Fp1
            offset( 0.03,  0.08, 0.05), // Fp2
            offset( 0.00,  0.09, 0.00), // Fz
            offset( 0.00,  0.10, -0.05) // Cz
        ]
    }
}
