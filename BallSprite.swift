//
//  BallSprite.swift
//  BubbleBeach
//
//  Created by Mathieu Knecht on 17.07.15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

import Foundation
import GameKit

class BallSprite: CCSprite {
    
    var airFriction = CGFloat(0.999)
    var initialPosition = ccp(0,0)
    var moving = false
    var delegate: BubbleDelegate?
    
    func didLoadFromCCB() {
        initialPosition = self.position
    }
    
    func isMoving ()-> Bool {
        return abs(self.physicsBody.velocity.x)>0.1 || abs(self.physicsBody.velocity.y)>0.1
    }
    
    func initState () {
        self.rotation = 0
        self.position = initialPosition
        self.physicsBody.velocity = ccp(0,0)
        self.physicsBody.angularVelocity = 0.0
    }
    
    override func update(delta: CCTime) {
        
        if (self.position.x > 520.0) {
            GameNetworking.sharedInstance.playerScore(true)
        }
        
        if (self.position.x < 45.0) {
            GameNetworking.sharedInstance.playerScore(false)
        }
        
        if isMoving(){
            
            if !moving {
                delegate?.bubbleUpdateStatus(true)
                moving = true
            }
            
            self.physicsBody.velocity = ccpMult(self.physicsBody.velocity, self.airFriction)
            self.physicsBody.angularVelocity = self.physicsBody.angularVelocity*self.airFriction
            if (abs(self.physicsBody.velocity.x)<50) && (abs(self.physicsBody.velocity.y)<50){
                //self.physicsBody.velocity = CGPointZero
                self.airFriction = CGFloat(0.97)
            }
        }else{
            if moving {
                delegate?.bubbleUpdateStatus(false)
                moving = false
                self.physicsBody.velocity = ccp(0,0)
                self.physicsBody.angularVelocity = 0.0
            }
        }
    }
    
}