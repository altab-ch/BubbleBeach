//
//  BubbleNode.swift
//  BubbleBeach
//
//  Created by Mathieu Knecht on 16.07.15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

import Foundation

protocol BubbleDelegate{
    func bubbleUpdateStatus(isMoving: Bool)
}

class BubbleNode: CCNode {
    
    var arrow = CCBReader.load("ArrowSprite") as! CCSprite
    var arrowPoint = ccp(0, 0)
    var airFriction = CGFloat(0.999)
    var isArrowAdded = false
    var initialPosition = ccp(0,0)
    var moving = false
    var delegate: BubbleDelegate?
    
    func didLoadFromCCB() {
        userInteractionEnabled = true
        self.physicsBody.mass = 25
        arrow.position = CGPointMake(30, 30)
        initialPosition = self.position
    }
    
    func initState () {
        self.rotation = 0
        self.position = initialPosition
        self.visible = true
        self.physicsBody.velocity = ccp(0,0)
        self.physicsBody.angularVelocity = 0.0
    }
    
    func launch(){
        
        self.removeArrow()
        
        self.airFriction = CGFloat(0.9995)
        self.physicsBody.applyImpulse(ccp(arrowPoint.x*40, arrowPoint.y*40))
        arrowPoint = ccp(0,0)
        
    }
    
    func removeArrow(){
        if isArrowAdded {
            self.removeChild(arrow)
            isArrowAdded = false
        }
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        
        //println("bubble pos : \(self.position.x) \(self.position.y)")
        
        self.setupArrow(touch)
        if !isArrowAdded {
            self.addChild(arrow, z: -1)
            isArrowAdded = true
        }
    }
    
    override func touchMoved(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        self.setupArrow(touch)
    }
    
    func setupArrow(touch: CCTouch!){
        let location = touch.locationInNode(self)
        let ptTouch = ccp(location.x-30.0,location.y-30.0)
        var dist = sqrt(ptTouch.x*ptTouch.x + ptTouch.y*ptTouch.y)/50.0
        let angle = atan2(ptTouch.y, ptTouch.x)
        
        var deg = CGFloat(angle) * CGFloat(180.0 / M_PI)
        var deg2 = CC_RADIANS_TO_DEGREES(Float(angle))
        arrow.scaleX = Float(dist)
        arrow.rotation = -Float(deg)
    }
    
    override func touchEnded(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        let location = touch.locationInNode(self)
        let ptTouch = ccp(location.x-30.0,location.y-30.0)
        arrowPoint = CGPointApplyAffineTransform(ptTouch, CGAffineTransformMakeRotation(CGFloat(-self.rotation).degreesToRadians))
        
        //println("touch stop : \(arrowPoint.x) \(arrowPoint.y)")
    }
    
    func isMoving ()-> Bool {
        return abs(self.physicsBody.velocity.x)>0.1 || abs(self.physicsBody.velocity.y)>0.1
    }
    
    override func update(delta: CCTime) {
        
        if (self.position.x < 45.0) || (self.position.x > 520.0) {
            self.physicsBody.velocity = ccp(0,0)
            self.physicsBody.angularVelocity = 0
            self.visible = false
            self.position = ccp(600, 0)
        }
        
        if (self.isMoving()){
            
            if !moving {
                delegate?.bubbleUpdateStatus(true)
                moving = true
            }
            
            if (self.position.x < 45.0) || (self.position.x > 520.0) {
                self.physicsBody.velocity = ccp(0,0)
                self.physicsBody.angularVelocity = 0
                self.visible = false
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