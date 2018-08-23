//
//  SpriteNode.swift
//  ARCharacter
//
//  Created by Sergii Nesteruk on 8/23/18.
//  Copyright © 2018 NLab. All rights reserved.
//

import SceneKit
import SpriteKit

class SpriteNode: SCNNode {
    
    static let spriteDimension: CGFloat = 0.1
    
    override init() {
        
        // Load animation frames from atlas
        let characterAtlas = SKTextureAtlas(named: "Character")
        var animationFrames = Array<SKTexture>()
        var maxHeight = 0.0
        var maxWidth = 0.0
        characterAtlas.textureNames.forEach { (name) in
            let texture = characterAtlas.textureNamed(name)
            animationFrames.append(texture)
            maxHeight = max(maxHeight, Double(texture.size().height))
            maxWidth = max(maxWidth, Double(texture.size().width))
        }
        let characterNode = SKSpriteNode(color: UIColor.clear, size: CGSize(width: maxWidth, height: maxHeight))
        characterNode.position = CGPoint(x: maxWidth / 2, y: maxHeight / 2)
        characterNode.texture = animationFrames[0]
        
        // Prepare SKScene as a material for SceneKit object
        let scene = SKScene(size: CGSize(width: maxWidth, height: maxHeight))
        scene.backgroundColor = UIColor.clear
        scene.addChild(characterNode)
        characterNode.run(SKAction.repeatForever(SKAction.animate(with: animationFrames, timePerFrame: 0.1, resize: true, restore: false)))
        
        // Define material
        let material = SCNMaterial()
        material.diffuse.contents = scene
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(1,-1,-1) // align texture in the right direction
        material.diffuse.wrapT = .repeat
        material.diffuse.wrapS = .repeat
        let plane = SCNPlane(width: SpriteNode.spriteDimension, height: SpriteNode.spriteDimension)
        plane.firstMaterial = material
        super.init()
        geometry = plane
        castsShadow = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
}
