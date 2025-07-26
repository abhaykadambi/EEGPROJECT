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
    var calibrationPoints: [SCNVector3] = []
    var calibrationNodes: [SCNNode] = []
    var meshAnchors: [ARMeshAnchor] = []
    var instructionLabel: UILabel!
    var resetButton: UIButton!
    var scanProgressView: UIProgressView!
    var calibrationStepLabel: UILabel!
    var eegNodes: [SCNNode] = []
    var infoTextView: UITextView!
    var nextButton: UIButton!
    
    // Face tracking properties
    var faceAnchor: ARFaceAnchor?
    var headNode: SCNNode?
    var isTrackingFace = false
    
    enum CalibrationState {
        case scanning
        case placeForehead
        case placeBackOfHead
        case complete
    }
    
    var currentState: CalibrationState = .scanning

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupARConfiguration()
        showInitialInstructions()
    }
    
    func setupUI() {
        sceneView = ARSCNView(frame: view.bounds)
        view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        instructionLabel = UILabel()
        instructionLabel.text = "Welcome to EEG Equipment Assistant"
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(instructionLabel)

        calibrationStepLabel = UILabel()
        calibrationStepLabel.text = "Step 1: Head Scanning"
        calibrationStepLabel.textColor = .yellow
        calibrationStepLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        calibrationStepLabel.textAlignment = .center
        calibrationStepLabel.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(calibrationStepLabel)

        scanProgressView = UIProgressView(progressViewStyle: .default)
        scanProgressView.progressTintColor = .green
        scanProgressView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(scanProgressView)

        infoTextView = UITextView()
        infoTextView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        infoTextView.textColor = .white
        infoTextView.font = UIFont.systemFont(ofSize: 14)
        infoTextView.isEditable = false
        infoTextView.isScrollEnabled = true
        infoTextView.layer.cornerRadius = 8
        infoTextView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(infoTextView)

        nextButton = UIButton(type: .system)
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        nextButton.layer.cornerRadius = 6
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextStep), for: .touchUpInside)
        nextButton.isHidden = true
        sceneView.addSubview(nextButton)

        resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        resetButton.layer.cornerRadius = 6
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetCalibration), for: .touchUpInside)
        sceneView.addSubview(resetButton)

        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: sceneView.safeAreaLayoutGuide.topAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: sceneView.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor, constant: -20),

            calibrationStepLabel.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            calibrationStepLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 10),

            scanProgressView.leadingAnchor.constraint(equalTo: sceneView.leadingAnchor, constant: 20),
            scanProgressView.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor, constant: -20),
            scanProgressView.topAnchor.constraint(equalTo: calibrationStepLabel.bottomAnchor, constant: 10),

            infoTextView.leadingAnchor.constraint(equalTo: sceneView.leadingAnchor, constant: 20),
            infoTextView.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor, constant: -20),
            infoTextView.topAnchor.constraint(equalTo: scanProgressView.bottomAnchor, constant: 10),
            infoTextView.heightAnchor.constraint(equalToConstant: 120),

            nextButton.topAnchor.constraint(equalTo: infoTextView.bottomAnchor, constant: 10),
            nextButton.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 100),
            nextButton.heightAnchor.constraint(equalToConstant: 40),

            resetButton.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 10),
            resetButton.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 120),
            resetButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func showInitialInstructions() {
        let welcomeText = """
        🧠 EEG Equipment Assistant
        
        This app helps you place EEG electrodes accurately using the international 10-20 system.
        
        What you'll need:
        • A person to scan
        • Good lighting
        • LiDAR-capable device (iPhone 12 Pro or later)
        
        The process:
        1. Scan the person's head with LiDAR
        2. Mark two key anatomical points
        3. View automatic electrode placement
        
        Tap "Next" to begin the head scanning process.
        """
        
        infoTextView.text = welcomeText
        nextButton.isHidden = false
        currentState = .scanning
    }
    
    @objc func nextStep() {
        switch currentState {
        case .scanning:
            startScanning()
        case .placeForehead:
            showForeheadInstructions()
        case .placeBackOfHead:
            showBackOfHeadInstructions()
        case .complete:
            showCompletionInfo()
        }
    }
    
    func startScanning() {
        currentState = .scanning
        nextButton.isHidden = true
        
        let scanningText = """
        📱 Step 1: LiDAR Head Scanning
        
        The app is now using LiDAR to create a precise 3D model of the person's head.
        
        Instructions:
        • Walk slowly around the person in a circle
        • Keep the device at arm's length
        • Ensure good lighting
        • Avoid rapid movements
        
        The progress bar shows scanning completion.
        When complete, you'll be prompted to place calibration markers.
        
        This creates the foundation for accurate electrode placement.
        """
        
        instructionLabel.text = "Scanning Head with LiDAR..."
        calibrationStepLabel.text = "Step 1: Head Scanning"
        infoTextView.text = scanningText
        scanProgressView.setProgress(0, animated: true)
        scanProgressView.progressTintColor = .green
    }
    
    func showForeheadInstructions() {
        let foreheadText = """
        👆 Step 2: Forehead Calibration
        
        You need to mark the Fpz position on the person's forehead.
        
        Fpz Location:
        • Center of the forehead
        • Above the bridge of the nose
        • Between the eyebrows
        • This is the reference point for frontal electrodes
        
        How to mark:
        1. Look at the person's forehead
        2. Tap exactly on the center point
        3. A green marker will appear
        
        This point helps establish the front-to-back orientation of the head.
        """
        
        instructionLabel.text = "Tap on the center of the forehead (Fpz position)"
        calibrationStepLabel.text = "Step 2: Mark Forehead (Fpz)"
        infoTextView.text = foreheadText
        scanProgressView.progressTintColor = .yellow
    }
    
    func showBackOfHeadInstructions() {
        let backOfHeadText = """
        👆 Step 3: Back of Head Calibration
        
        You need to mark the Inion position on the back of the head.
        
        Inion Location:
        • Back of the head, center
        • Below the occipital protuberance
        • Where the neck meets the skull
        • This is the reference point for occipital electrodes
        
        How to mark:
        1. Move to the back of the person's head
        2. Tap on the center point at the base of the skull
        3. A blue marker will appear
        
        This point helps establish the head length and orientation.
        """
        
        instructionLabel.text = "Tap on the back of the head (Inion position)"
        calibrationStepLabel.text = "Step 3: Mark Back of Head (Inion)"
        infoTextView.text = backOfHeadText
        scanProgressView.progressTintColor = .orange
    }
    
    func showCompletionInfo() {
        let completionText = """
        ✅ Calibration Complete!
        
        The app has automatically placed EEG electrodes according to the international 10-20 system.
        
        Electrode Positions:
        • Fp1, Fp2: Frontal poles (left/right)
        • Fz: Frontal midline
        • Cz: Central midline (vertex)
        • Pz: Parietal midline
        • O1, O2: Occipital (left/right)
        • T3, T4: Temporal (left/right)
        
        The 10-20 system ensures standardized electrode placement across different head sizes.
        
        Red markers show electrode positions.
        Green marker: Fpz (forehead reference)
        Blue marker: Inion (back reference)
        
        Switching to face tracking mode - electrodes will now follow your head movements!
        """
        
        instructionLabel.text = "EEG Electrodes Placed Successfully!"
        calibrationStepLabel.text = "Complete: 10-20 System Applied"
        infoTextView.text = completionText
        scanProgressView.progressTintColor = .green
        nextButton.setTitle("View Details", for: .normal)
        nextButton.isHidden = false
        
        // Switch to face tracking after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.switchToFaceTracking()
        }
    }
    
    func setupARConfiguration() {
        // Start with world tracking for LiDAR scanning
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravity
        config.sceneReconstruction = .meshWithClassification
        config.environmentTexturing = .automatic
        config.frameSemantics = .sceneDepth
        
        // Enable LiDAR-specific features
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        }
        
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func switchToFaceTracking() {
        // Switch to face tracking after electrode placement
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Face tracking not supported on this device")
            return
        }
        
        let faceConfig = ARFaceTrackingConfiguration()
        faceConfig.worldAlignment = .gravity
        
        sceneView.session.run(faceConfig, options: [.resetTracking, .removeExistingAnchors])
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let meshAnchor = anchor as? ARMeshAnchor {
            meshAnchors.append(meshAnchor)
            let progress = min(Float(meshAnchors.count) / 50.0, 1.0)
            DispatchQueue.main.async {
                self.scanProgressView.setProgress(progress, animated: true)
                if self.meshAnchors.count > 30 && self.currentState == .scanning {
                    self.transitionToCalibration()
                }
            }
        }
        
        // Handle face anchor for real-time tracking
        if let faceAnchor = anchor as? ARFaceAnchor {
            self.faceAnchor = faceAnchor
            self.isTrackingFace = true
            
            // Create a head node that will follow the face
            if headNode == nil {
                headNode = SCNNode()
                node.addChildNode(headNode!)
                
                // If electrodes are already placed, attach them to the face
                if currentState == .complete {
                    attachElectrodesToFace()
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Face tracking updates happen automatically when electrodes are attached to face node
        if let faceAnchor = anchor as? ARFaceAnchor {
            self.faceAnchor = faceAnchor
        }
    }
    

    
    func transitionToCalibration() {
        currentState = .placeForehead
        DispatchQueue.main.async {
            self.showForeheadInstructions()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let location = touch.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, types: [.featurePoint, .estimatedHorizontalPlane, .estimatedVerticalPlane])

        if let result = hitResults.first {
            let position = SCNVector3(
                result.worldTransform.columns.3.x,
                result.worldTransform.columns.3.y,
                result.worldTransform.columns.3.z
            )

            handleCalibrationTap(at: position)
        }
    }
    
    func handleCalibrationTap(at position: SCNVector3) {
        switch currentState {
        case .placeForehead:
            placeCalibrationPoint(at: position, label: "Fpz", color: .green)
            calibrationPoints.append(position)
            currentState = .placeBackOfHead
            DispatchQueue.main.async {
                self.showBackOfHeadInstructions()
            }
            
        case .placeBackOfHead:
            placeCalibrationPoint(at: position, label: "Inion", color: .blue)
            calibrationPoints.append(position)
            currentState = .complete
            DispatchQueue.main.async {
                self.placeEEGElectrodes()
                self.showCompletionInfo()
            }
            
        default:
            break
        }
    }
    
    func placeCalibrationPoint(at position: SCNVector3, label: String, color: UIColor) {
        let dot = makeDot(color: color, radius: 0.008)
        dot.position = position
        sceneView.scene.rootNode.addChildNode(dot)
        calibrationNodes.append(dot)
        
        let text = makeLabel(text: label)
        text.position = SCNVector3(position.x, position.y + 0.015, position.z)
        sceneView.scene.rootNode.addChildNode(text)
        calibrationNodes.append(text)
    }
    
    func placeEEGElectrodes() {
        guard calibrationPoints.count == 2 else { return }
        
        let forehead = calibrationPoints[0]  // Fpz
        let inion = calibrationPoints[1]     // Inion
        
        // Calculate head dimensions and orientation
        let headLength = simd_distance(SIMD3<Float>(forehead), SIMD3<Float>(inion))
        let headCenter = SCNVector3(
            (forehead.x + inion.x) / 2,
            (forehead.y + inion.y) / 2,
            (forehead.z + inion.z) / 2
        )
        
        // Calculate head width (approximate)
        let headWidth = headLength * 0.8 // Typical head width is about 80% of length
        
        // Place electrodes according to 10-20 system
        let electrodes = calculateElectrodePositions(
            forehead: forehead,
            inion: inion,
            headLength: headLength,
            headWidth: headWidth
        )
        
        for (label, position) in electrodes {
            let electrode = makeDot(color: .red, radius: 0.006)
            electrode.position = position
            sceneView.scene.rootNode.addChildNode(electrode)
            eegNodes.append(electrode)
            
            let text = makeLabel(text: label)
            text.position = SCNVector3(position.x, position.y + 0.012, position.z)
            sceneView.scene.rootNode.addChildNode(text)
            eegNodes.append(text)
        }
        
        // Switch to face tracking after electrode placement
        switchToFaceTracking()
    }
    
    func calculateElectrodePositions(forehead: SCNVector3, inion: SCNVector3, headLength: Float, headWidth: Float) -> [(String, SCNVector3)] {
        let headCenter = SCNVector3(
            (forehead.x + inion.x) / 2,
            (forehead.y + inion.y) / 2,
            (forehead.z + inion.z) / 2
        )
        
        // Calculate the direction vector from forehead to inion
        let direction = simd_normalize(SIMD3<Float>(inion) - SIMD3<Float>(forehead))
        
        // Calculate perpendicular direction for left-right positioning
        let up = SIMD3<Float>(0, 1, 0)
        let right = simd_normalize(simd_cross(direction, up))
        let left = -right
        
        var electrodes: [(String, SCNVector3)] = []
        
        // Frontal electrodes (10% from forehead)
        let fp1 = SCNVector3(
            forehead.x + left.x * headWidth * 0.1,
            forehead.y + left.y * headWidth * 0.1,
            forehead.z + left.z * headWidth * 0.1
        )
        electrodes.append(("Fp1", fp1))
        
        let fp2 = SCNVector3(
            forehead.x + right.x * headWidth * 0.1,
            forehead.y + right.y * headWidth * 0.1,
            forehead.z + right.z * headWidth * 0.1
        )
        electrodes.append(("Fp2", fp2))
        
        // Central electrodes (20% from forehead)
        let fz = SCNVector3(
            forehead.x + direction.x * headLength * 0.2,
            forehead.y + direction.y * headLength * 0.2,
            forehead.z + direction.z * headLength * 0.2
        )
        electrodes.append(("Fz", fz))
        
        // Midline electrodes
        let cz = SCNVector3(
            forehead.x + direction.x * headLength * 0.5,
            forehead.y + direction.y * headLength * 0.5,
            forehead.z + direction.z * headLength * 0.5
        )
        electrodes.append(("Cz", cz))
        
        let pz = SCNVector3(
            forehead.x + direction.x * headLength * 0.7,
            forehead.y + direction.y * headLength * 0.7,
            forehead.z + direction.z * headLength * 0.7
        )
        electrodes.append(("Pz", pz))
        
        // Occipital electrodes (10% from inion)
        let o1 = SCNVector3(
            inion.x + left.x * headWidth * 0.1,
            inion.y + left.y * headWidth * 0.1,
            inion.z + left.z * headWidth * 0.1
        )
        electrodes.append(("O1", o1))
        
        let o2 = SCNVector3(
            inion.x + right.x * headWidth * 0.1,
            inion.y + right.y * headWidth * 0.1,
            inion.z + right.z * headWidth * 0.1
        )
        electrodes.append(("O2", o2))
        
        // Temporal electrodes
        let t3 = SCNVector3(
            headCenter.x + left.x * headWidth * 0.4,
            headCenter.y + left.y * headWidth * 0.4,
            headCenter.z + left.z * headWidth * 0.4
        )
        electrodes.append(("T3", t3))
        
        let t4 = SCNVector3(
            headCenter.x + right.x * headWidth * 0.4,
            headCenter.y + right.y * headWidth * 0.4,
            headCenter.z + right.z * headWidth * 0.4
        )
        electrodes.append(("T4", t4))
        
        return electrodes
    }

    func attachElectrodesToFace() {
        guard let headNode = headNode else { return }
        
        // Remove electrodes from scene root and attach to face
        for node in eegNodes {
            node.removeFromParentNode()
            headNode.addChildNode(node)
        }
        
        for node in calibrationNodes {
            node.removeFromParentNode()
            headNode.addChildNode(node)
        }
    }

    @objc func resetCalibration() {
        currentState = .scanning
        calibrationPoints.removeAll()
        meshAnchors.removeAll()
        isTrackingFace = false
        faceAnchor = nil
        headNode = nil
        
        // Remove all nodes
        calibrationNodes.forEach { $0.removeFromParentNode() }
        calibrationNodes.removeAll()
        eegNodes.forEach { $0.removeFromParentNode() }
        eegNodes.removeAll()
        
        DispatchQueue.main.async {
            self.showInitialInstructions()
        }
        
        // Reset AR session
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravity
        config.sceneReconstruction = .meshWithClassification
        config.environmentTexturing = .automatic
        config.frameSemantics = .sceneDepth
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        }
        
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func makeDot(color: UIColor, radius: Float) -> SCNNode {
        let sphere = SCNSphere(radius: CGFloat(radius))
        sphere.firstMaterial?.diffuse.contents = color
        sphere.firstMaterial?.emission.contents = color.withAlphaComponent(0.3)
        return SCNNode(geometry: sphere)
    }

    func makeLabel(text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.001)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.font = UIFont.systemFont(ofSize: 0.1)
        textGeometry.flatness = 0.1

        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.003, 0.003, 0.003)
        
        // Center the text
        let (min, max) = textGeometry.boundingBox
        let dx = Float(max.x - min.x) * 0.003 / 2
        textNode.position.x -= dx
        
        return textNode
    }
}
