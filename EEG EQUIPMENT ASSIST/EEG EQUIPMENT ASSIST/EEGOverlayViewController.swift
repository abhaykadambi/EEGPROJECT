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
    
    enum CalibrationState {
        case scanning
        case placeForehead
        case placeBackOfHead
        case placeVertex  // NEW: Add vertex calibration step
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
        2. Mark three key anatomical points
        3. View automatic electrode placement with arc-based positioning
        
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
        case .placeVertex:
            showVertexInstructions()
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
        • Make sure to scan the TOP of the head thoroughly
        • Keep the device at arm's length
        • Ensure good lighting
        • Avoid rapid movements
        
        The progress bar shows scanning completion.
        When complete, you'll be prompted to place three calibration markers.
        
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
    
    func showVertexInstructions() {
        let vertexText = """
        👆 Step 4: Top of Head Calibration
        
        You need to mark the Cz position (vertex) on the top of the head.
        
        Cz Location:
        • Top center of the head (vertex)
        • Highest point when looking down at the head
        • This is the reference point for central electrodes
        
        How to mark:
        1. Look down at the person's head from above
        2. Tap exactly on the highest point (vertex)
        3. A purple marker will appear
        
        This point helps establish the head height and curvature.
        """
        
        instructionLabel.text = "Tap on the top center of the head (Cz position)"
        calibrationStepLabel.text = "Step 4: Mark Top of Head (Cz)"
        infoTextView.text = vertexText
        scanProgressView.progressTintColor = .purple
    }
    
    func showCompletionInfo() {
        let completionText = """
        ✅ Calibration Complete!
        
        The app has automatically placed all 21 EEG electrodes according to the international 10-20 system using arc-based positioning.
        
        Electrode Positions:
        • Fp1, Fp2: Frontal poles (left/right)
        • Fz, F3, F4, F7, F8: Frontal region
        • Cz, C3, C4: Central region (vertex and lateral)
        • T3, T4, T5, T6: Temporal regions (mid and posterior)
        • Pz, P3, P4: Parietal region
        • O1, O2: Occipital region (back of head)
        • A1, A2: Aural reference points (earlobes)
        
        The 10-20 system ensures standardized electrode placement across different head sizes with comprehensive coverage of the entire scalp.
        
        Arc-based positioning follows the natural curvature of the head for more accurate placement.
        
        Red markers show electrode positions.
        Green marker: Fpz (forehead reference)
        Blue marker: Inion (back reference)
        Purple marker: Cz (vertex reference)
        
        You can now place physical electrodes at these marked positions.
        """
        
        instructionLabel.text = "EEG Electrodes Placed Successfully!"
        calibrationStepLabel.text = "Complete: Full 10-20 System Applied"
        infoTextView.text = completionText
        scanProgressView.progressTintColor = .green
        nextButton.setTitle("View Details", for: .normal)
        nextButton.isHidden = false
    }
    
    func setupARConfiguration() {
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
            currentState = .placeVertex  // NEW: Go to vertex instead of complete
            DispatchQueue.main.async {
                self.showVertexInstructions()
            }
            
        case .placeVertex:  // NEW: Handle vertex calibration
            placeCalibrationPoint(at: position, label: "Cz", color: .purple)
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
        guard calibrationPoints.count == 3 else { return } // Changed from 2 to 3
        
        let forehead = calibrationPoints[0]  // Fpz
        let inion = calibrationPoints[1]     // Inion
        let vertex = calibrationPoints[2]    // Cz (NEW)
        
        // Calculate head dimensions and orientation
        let headLength = simd_distance(SIMD3<Float>(forehead), SIMD3<Float>(inion))
        let headWidth = headLength * 0.8 // Typical head width is about 80% of length
        
        // Place electrodes according to 10-20 system with arc-based positioning
        let electrodes = calculateElectrodePositions(
            forehead: forehead,
            inion: inion,
            vertex: vertex,  // NEW: Use actual vertex point
            headLength: headLength,
            headWidth: headWidth
        )
        
        for (label, arcPosition) in electrodes {
            // Project the electrode position onto the actual head surface
            let surfacePosition = projectElectrodeToSurface(position: arcPosition)
            
            let electrode = makeDot(color: .red, radius: 0.006)
            electrode.position = surfacePosition
            sceneView.scene.rootNode.addChildNode(electrode)
            eegNodes.append(electrode)
            
            let text = makeLabel(text: label)
            text.position = SCNVector3(surfacePosition.x, surfacePosition.y + 0.012, surfacePosition.z)
            sceneView.scene.rootNode.addChildNode(text)
            eegNodes.append(text)
        }
    }
    
    // Simple surface projection using ARKit ray casting
    func projectElectrodeToSurface(position: SCNVector3) -> SCNVector3 {
        // Cast a ray downward from above the position to find the head surface
        let rayStart = SCNVector3(position.x, position.y + 0.2, position.z) // Start 20cm above
        let rayEnd = SCNVector3(position.x, position.y - 0.2, position.z)   // End 20cm below
        
        // Use SceneKit's built-in ray casting against the scene
        let hitResults = sceneView.scene.rootNode.hitTestWithSegment(
            from: rayStart,
            to: rayEnd,
            options: [
                "searchMode": SCNHitTestSearchMode.closest.rawValue,
                "ignoreHiddenNodes": true
            ]
        )
        
        if let hitResult = hitResults.first {
            return hitResult.worldCoordinates
        }
        
        return position // Fallback to original position
    }

    func calculateElectrodePositions(forehead: SCNVector3, inion: SCNVector3, vertex: SCNVector3, headLength: Float, headWidth: Float) -> [(String, SCNVector3)] {
        // Calculate head center and orientation vectors
        let headCenter = SCNVector3(
            (forehead.x + inion.x) / 2,
            (forehead.y + inion.y) / 2,
            (forehead.z + inion.z) / 2
        )
        
        // Direction vectors
        let frontToBack = simd_normalize(SIMD3<Float>(inion) - SIMD3<Float>(forehead))
        let up = SIMD3<Float>(0, 1, 0)
        let leftToRight = simd_normalize(simd_cross(frontToBack, up))
        
        var electrodes: [(String, SCNVector3)] = []
        
        // Helper function to create arc-based positions
        func createArcPosition(basePoint: SCNVector3, arcAngle: Float, lateralOffset: Float, heightOffset: Float) -> SCNVector3 {
            // Create an arc from the base point
            let arcRadius = headWidth * 0.3 // Adjust based on head size
            let arcX = basePoint.x + leftToRight.x * lateralOffset
            let arcY = basePoint.y + heightOffset
            let arcZ = basePoint.z + leftToRight.z * lateralOffset
            
            // Apply arc curvature
            let curvature = sin(arcAngle) * arcRadius
            return SCNVector3(arcX, arcY + curvature, arcZ)
        }
        
        // Frontal arc (Fp1, Fp2, Fz, F3, F4, F7, F8)
        let frontalBase = forehead
        electrodes.append(("Fp1", createArcPosition(basePoint: frontalBase, arcAngle: 0.3, lateralOffset: -headWidth * 0.1, heightOffset: 0)))
        electrodes.append(("Fp2", createArcPosition(basePoint: frontalBase, arcAngle: 0.3, lateralOffset: headWidth * 0.1, heightOffset: 0)))
        electrodes.append(("Fz", createArcPosition(basePoint: frontalBase, arcAngle: 0.2, lateralOffset: 0, heightOffset: headLength * 0.1)))
        electrodes.append(("F3", createArcPosition(basePoint: frontalBase, arcAngle: 0.4, lateralOffset: -headWidth * 0.2, heightOffset: headLength * 0.1)))
        electrodes.append(("F4", createArcPosition(basePoint: frontalBase, arcAngle: 0.4, lateralOffset: headWidth * 0.2, heightOffset: headLength * 0.1)))
        electrodes.append(("F7", createArcPosition(basePoint: frontalBase, arcAngle: 0.6, lateralOffset: -headWidth * 0.4, heightOffset: headLength * 0.1)))
        electrodes.append(("F8", createArcPosition(basePoint: frontalBase, arcAngle: 0.6, lateralOffset: headWidth * 0.4, heightOffset: headLength * 0.1)))
        
        // Central arc (Cz, C3, C4, T3, T4, A1, A2)
        electrodes.append(("Cz", vertex)) // Vertex is already the Cz position
        electrodes.append(("C3", createArcPosition(basePoint: vertex, arcAngle: 0.3, lateralOffset: -headWidth * 0.2, heightOffset: 0)))
        electrodes.append(("C4", createArcPosition(basePoint: vertex, arcAngle: 0.3, lateralOffset: headWidth * 0.2, heightOffset: 0)))
        electrodes.append(("T3", createArcPosition(basePoint: vertex, arcAngle: 0.5, lateralOffset: -headWidth * 0.4, heightOffset: 0)))
        electrodes.append(("T4", createArcPosition(basePoint: vertex, arcAngle: 0.5, lateralOffset: headWidth * 0.4, heightOffset: 0)))
        electrodes.append(("A1", createArcPosition(basePoint: vertex, arcAngle: 0.7, lateralOffset: -headWidth * 0.5, heightOffset: 0)))
        electrodes.append(("A2", createArcPosition(basePoint: vertex, arcAngle: 0.7, lateralOffset: headWidth * 0.5, heightOffset: 0)))
        
        // Parietal arc (Pz, P3, P4, T5, T6)
        let parietalBase = SCNVector3(
            forehead.x + frontToBack.x * headLength * 0.7,
            forehead.y + frontToBack.y * headLength * 0.7,
            forehead.z + frontToBack.z * headLength * 0.7
        )
        electrodes.append(("Pz", createArcPosition(basePoint: parietalBase, arcAngle: 0.2, lateralOffset: 0, heightOffset: 0)))
        electrodes.append(("P3", createArcPosition(basePoint: parietalBase, arcAngle: 0.4, lateralOffset: -headWidth * 0.2, heightOffset: 0)))
        electrodes.append(("P4", createArcPosition(basePoint: parietalBase, arcAngle: 0.4, lateralOffset: headWidth * 0.2, heightOffset: 0)))
        electrodes.append(("T5", createArcPosition(basePoint: parietalBase, arcAngle: 0.6, lateralOffset: -headWidth * 0.4, heightOffset: 0)))
        electrodes.append(("T6", createArcPosition(basePoint: parietalBase, arcAngle: 0.6, lateralOffset: headWidth * 0.4, heightOffset: 0)))
        
        // Occipital arc (O1, O2)
        electrodes.append(("O1", createArcPosition(basePoint: inion, arcAngle: 0.3, lateralOffset: -headWidth * 0.1, heightOffset: 0)))
        electrodes.append(("O2", createArcPosition(basePoint: inion, arcAngle: 0.3, lateralOffset: headWidth * 0.1, heightOffset: 0)))
        
        return electrodes
    }

    @objc func resetCalibration() {
        currentState = .scanning
        calibrationPoints.removeAll()
        meshAnchors.removeAll()
        
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
    
    // Helper function to convert world position to screen coordinates
    func convertWorldPositionToScreen(_ worldPosition: SCNVector3) -> CGPoint {
        // Get the current camera frame
        guard let currentFrame = sceneView.session.currentFrame else {
            return CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
        }
        
        let cameraTransform = currentFrame.camera.transform
        let projectionMatrix = currentFrame.camera.projectionMatrix
        
        // Convert world position to camera space
        let worldVector = simd_float4(worldPosition.x, worldPosition.y, worldPosition.z, 1.0)
        let cameraSpaceVector = simd_mul(cameraTransform, worldVector)
        
        // Apply projection
        let projectedVector = simd_mul(projectionMatrix, cameraSpaceVector)
        
        // Convert to normalized device coordinates
        let normalizedX = projectedVector[0] / projectedVector[3]
        let normalizedY = projectedVector[1] / projectedVector[3]
        
        // Convert to screen coordinates with proper type conversion
        let screenX = CGFloat(normalizedX + 1.0) * 0.5 * sceneView.bounds.width
        let screenY = CGFloat(1.0 - normalizedY) * 0.5 * sceneView.bounds.height
        
        return CGPoint(x: screenX, y: screenY)
    }
}