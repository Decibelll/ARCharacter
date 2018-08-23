//
//  SceneLightNode.swift
//  ARCharacter
//
//  Created by Sergii Nesteruk on 8/23/18.
//  Copyright © 2018 NLab. All rights reserved.
//

import SceneKit

class SceneLightNode: SCNNode {
    
    override init() {
        
        let light = SCNLight()
        light.castsShadow = true
        light.type = .spot
        light.spotInnerAngle = 45
        light.spotOuterAngle = 45
        light.shadowMode = .deferred
        light.shadowSampleCount = 64
        light.shadowMapSize = CGSize(width: 2048, height: 2048)
        
        super.init()
        self.light = light
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
}
