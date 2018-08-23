//
//  ARViewController.swift
//  ARCharacter
//
//  Created by Sergii Nesteruk on 8/17/18.
//  Copyright © 2018 NLab. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var character3DNode: SCNNode?
    private var shadowNode: SCNNode?
    private var trackingPlaneNode: TrackingSquare?
    private var horizontalPlaneAnchor: ARPlaneAnchor?
    private weak var horizontalPlaneNode: SCNNode?
    private weak var tapGestureRecognizer: UITapGestureRecognizer?
    private weak var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    // MARK: - Lifecycle callbacks
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        sceneView.delegate = self
        addLight()
        
        // Add gesture recognizers
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(gestureRecognizer:)))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(gestureRecognizer:)))
        longPressGestureRecognizer.isEnabled = false
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        sceneView.addGestureRecognizer(longPressGestureRecognizer)
        self.tapGestureRecognizer = tapGestureRecognizer
        self.longPressGestureRecognizer = longPressGestureRecognizer
        updateStatus(message: "Searching flat horizontal surface...\nSlowly move camera around")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // Disabling sleep when in AR
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Create a session configuration which will detect horizontal planes
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]

        // Run the view's session
        sceneView.session.run(configuration)
        
        addTrackingSquare(for: .searching)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        // Enable sleep when leaving AR
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // MARK: - Gestures handling

    @IBAction func resetButtonTapped() {
        resetTracking()
    }
    
    @objc func tapGestureRecognized(gestureRecognizer: UITapGestureRecognizer) {
        
        let tapLocation = gestureRecognizer.location(in: sceneView)
        let searchOptions = [SCNHitTestOption.searchMode: NSNumber(integerLiteral: SCNHitTestSearchMode.closest.rawValue)]
        if let result = sceneView.hitTest(tapLocation, options: searchOptions).first, result.node is TrackingSquare {
            let spritePosition = result.node.convertPosition(result.localCoordinates, to: horizontalPlaneNode)
            addSpriteKitSolution(to: horizontalPlaneNode!, with: horizontalPlaneAnchor!, at: spritePosition)
            result.node.removeFromParentNode()
            gestureRecognizer.isEnabled = false
            longPressGestureRecognizer?.isEnabled = true
            updateStatus(message: "You may remove character by long pressing on one.")
        }
    }
    
    @objc func longPressGestureRecognized(gestureRecognizer: UILongPressGestureRecognizer) {
        
        let tapLocation = gestureRecognizer.location(in: sceneView)
        let searchOptions = [SCNHitTestOption.searchMode: NSNumber(integerLiteral: SCNHitTestSearchMode.closest.rawValue)]
        if let result = sceneView.hitTest(tapLocation, options: searchOptions).first,
            result.node == character3DNode {
            character3DNode?.removeFromParentNode()
            shadowNode?.removeFromParentNode()
            addTrackingSquare(for: .detected)
            gestureRecognizer.isEnabled = false
            tapGestureRecognizer?.isEnabled = true
            updateStatus(message: "Tap highlighted area to add the character.")
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // we only track 1 horizontal plane currently - for simplicity and making test app more stable
        guard horizontalPlaneAnchor == nil else { return }
        
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        horizontalPlaneAnchor = planeAnchor
        horizontalPlaneNode = node
        if let trackingNode = self.trackingPlaneNode {
            trackingNode.changeTrackingMode(mode: .detected)
            trackingNode.position = SCNVector3(planeAnchor.center)
            trackingNode.eulerAngles.x = -.pi / 2
            node.addChildNode(trackingNode)
            updateStatus(message: "Found flat surface! Tap highlighted area to add the character.")
        }
        else {
            print("Error: tracking node isn't found when horizontal plane detected.")
            updateStatus(message: "Error.\nPlease press reset.")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        // We only update anchor if trackingPlaneNode is still in .searching mode
        guard
            let trackingSquare = trackingPlaneNode,
            trackingSquare.currentTrackingMode == .detected,
            let horizontalPlane = horizontalPlaneNode,
            horizontalPlane == node,
            let planeAnchor = anchor as? ARPlaneAnchor
        else { return }
        
        (trackingSquare.geometry as? SCNPlane)?.width = CGFloat(planeAnchor.extent.x)
        (trackingSquare.geometry as? SCNPlane)?.height = CGFloat(planeAnchor.extent.z)
        trackingSquare.simdPosition = planeAnchor.center
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        // In .searching mode we update the tilting of tracking square to correlate with tilting of camera
        if let trackingNode = trackingPlaneNode,
            let cameraNode = sceneView.pointOfView,
            trackingNode.currentTrackingMode == .searching {
            trackingNode.eulerAngles.x = -.pi / 2 - cameraNode.eulerAngles.x
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        
        updateStatus(message: "AR session was interrupted.\nWill reset on restore.")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        
        // When interruption ends we reset tracking of planes
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        
        // General failure - try to reset plane tracking
        resetTracking()
    }
    
    // MARK: - Private utility methods
    
    private func resetTracking() {
        
        // Do cleanup
        horizontalPlaneAnchor = nil
        horizontalPlaneNode = nil
        character3DNode?.removeFromParentNode()
        character3DNode = nil
        shadowNode?.removeFromParentNode()
        shadowNode = nil
        
        // Reconfigure the AR session for horizontal plane tracking
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        tapGestureRecognizer?.isEnabled = true
        longPressGestureRecognizer?.isEnabled = false
        addTrackingSquare(for: .searching)
        updateStatus(message: "Searching flat horizontal surface...\nSlowly move camera around")
    }
    
    private func addSpriteKitSolution(to node: SCNNode, with anchor: ARPlaneAnchor, at location: SCNVector3) {
        
        // Update sprite location to move it up the plane
        var spriteLocation = location
        spriteLocation.y = Float(SpriteNode.spriteDimension / 2)
        
        // Add anchor at sprite's position to better track this area
        let anchorTransform = SCNMatrix4Translate(SCNMatrix4(anchor.transform), spriteLocation.x, spriteLocation.y, spriteLocation.z)
        let spriteAnchor = ARAnchor(transform: matrix_float4x4(anchorTransform))
        sceneView.session.add(anchor: spriteAnchor)
        
        // Add 2D sprite node
        character3DNode = SpriteNode()
        character3DNode!.position = SCNVector3(spriteAnchor.transform.columns.3.x, spriteAnchor.transform.columns.3.y, spriteAnchor.transform.columns.3.z)
        character3DNode!.constraints = [SCNBillboardConstraint()] // Always point 2d sprite to camera
        sceneView.scene.rootNode.addChildNode(character3DNode!)
        
        // Add shadow plane
        let shadowPlane = SCNPlane(width: 5, height: 5)
        shadowPlane.materials.first?.colorBufferWriteMask = .alpha
        shadowNode = SCNNode(geometry: shadowPlane)
        shadowNode!.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0) // because plane is created vertical
        shadowNode!.position = SCNVector3(anchor.center)
        node.addChildNode(shadowNode!)
    }
    
    private func addLight() {
        
        let lightNode = SceneLightNode()
        lightNode.position = SCNVector3(-1, 5, 2) // Position of light is selected to make some offset shadow on the scene
        lightNode.eulerAngles.x = -.pi * 7 / 16 // Making some tilt of the light to make shadow visible
        sceneView.scene.rootNode.addChildNode(lightNode)
    }
    
    private func addTrackingSquare(for mode: TrackingSquare.TrackingMode) {
        
        if trackingPlaneNode == nil {
            
            trackingPlaneNode = TrackingSquare()
        }
        trackingPlaneNode?.changeTrackingMode(mode: mode)
        switch mode {
        case .detected:
            if let horizontalPlane = horizontalPlaneNode,
                let planeAnchor = horizontalPlaneAnchor {
                (trackingPlaneNode?.geometry as? SCNPlane)?.width = CGFloat(planeAnchor.extent.x)
                (trackingPlaneNode?.geometry as? SCNPlane)?.height = CGFloat(planeAnchor.extent.z)
                trackingPlaneNode?.simdPosition = planeAnchor.center
                horizontalPlane.addChildNode(trackingPlaneNode!)
            }
            
        case .searching:
            if let cameraNode = sceneView.pointOfView, let trackingNode = trackingPlaneNode {
                trackingNode.resetState()
                cameraNode.addChildNode(trackingNode)
            }
        }
    }
    
    private func updateStatus(message: String) {
        
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }
}
