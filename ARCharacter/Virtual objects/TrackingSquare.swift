//
//  TrackingSquare.swift
//  ARCharacter
//
//  Created by Sergii Nesteruk on 8/22/18.
//  Copyright © 2018 NLab. All rights reserved.
//

import SceneKit

class TrackingSquare: SCNNode {

    enum TrackingMode: Equatable {
        case searching
        case detected
    }
    
    private let planeDimension: CGFloat = 0.3
    private let segmentsShaderString = """
#pragma body
float u = _surface.diffuseTexcoord.x;
float v = _surface.diffuseTexcoord.y;
float2 thickness = float2(0.01);
float2 segmentLength = float2(0.15);
if ((u > thickness[0] && u < (1.0 - thickness[0]) && v > thickness[1] && v < (1.0 - thickness[1])) || (u > segmentLength[0] && u < (1.0 - segmentLength[0])) || (v > segmentLength[1] && v < (1.0 - segmentLength[1]))) {
discard_fragment();
}
"""
    
    private var trackingPlane: SCNPlane
    var currentTrackingMode = TrackingMode.searching

    override init() {
        
        trackingPlane = SCNPlane(width: planeDimension, height: planeDimension)
        trackingPlane.materials.first?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.5)
        trackingPlane.materials.first?.shaderModifiers = [.surface: segmentsShaderString]
        super.init()
        
        self.geometry = trackingPlane
        self.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0) // Plane is created vertical - turn it 90 deg
        self.position = SCNVector3(0, -0.25, -1) // Position of tracking square is fixed for simplicity
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        trackingPlane = SCNPlane(width: planeDimension, height: planeDimension)
        super.init(coder: aDecoder)
    }
    
    func changeTrackingMode(mode: TrackingMode) {
        
        currentTrackingMode = mode
        switch currentTrackingMode {
        case .searching:
            trackingPlane.materials.first?.shaderModifiers = [.surface: segmentsShaderString]
            
        case .detected:
            trackingPlane.materials.first?.shaderModifiers = nil
        }
    }
    
    func resetState()
    {
        trackingPlane.width = planeDimension
        trackingPlane.height = planeDimension
        self.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0) // Plane is created vertical - turn it 90 deg
        self.position = SCNVector3(0, -0.25, -1) // Position of tracking square is fixed for simplicity
    }
}
