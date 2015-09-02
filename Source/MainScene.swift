//
//  MainScene.swift
//  BubbleBeach
//
//  Created by Mathieu Knecht on 16.07.15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

import Foundation

class MainScene: CCNode,  GameNetworkingDelegate, BubbleDelegate {
    
    weak var ball: BallSprite!
    weak var bubble1: BubbleNode!
    weak var bubble2: BubbleNode!
    weak var bubble3: BubbleNode!
    weak var bubble4: BubbleNode!
    weak var bubble5: BubbleNode!
    weak var bubble6: BubbleNode!
    weak var lbWaiting: CCLabelTTF!
    weak var lbGoal: CCLabelTTF!
    weak var score2: CCLabelTTF!
    weak var score1: CCLabelTTF!
    
    var bubbles: [BubbleNode] = []
    var opponentBubbles: [BubbleNode] = []
    var allBubbles: [BubbleNode] = []
    var elementMoving = 0
    var replay: [Double : [[Float]]] = [:]
    var isRecording = false
    var lapse: Double = 0.0
    var nextRecord: Double = 0.0
    var nextRecordPos: Int = 0
    var replayKeys : [Double] = []
    var isReplaying = false
    
    func didLoadFromCCB() {
        lbWaiting.visible = false
        lbGoal.visible = false
        score1.string = "0"
        score2.string = "0"
        
        if GameNetworking.sharedInstance.is1stPlayer {
            bubbles = [bubble1, bubble2, bubble3]
            opponentBubbles = [bubble4, bubble5, bubble6]
        }else{
            opponentBubbles = [bubble1, bubble2, bubble3]
            bubbles = [bubble4, bubble5, bubble6]
        }
        
        allBubbles = bubbles + opponentBubbles
        
        for bubble in opponentBubbles {
            bubble.userInteractionEnabled = false
        }
        
        for bubble in allBubbles {
            bubble.delegate = self
        }
        
        ball.delegate = self
    }
    
    func playerReady(){
        
        if GameNetworking.sharedInstance.is1stPlayer {
            if !GameNetworking.sharedInstance.hasReceivedData {
                lbWaiting.visible = true
            }
            GameNetworking.sharedInstance.ready()
        }else{
            var array: [Float] = []
            
            for bubble in bubbles {
                array.append(Float(bubble.arrowPoint.x))
                array.append(Float(bubble.arrowPoint.y))
            }
            GameNetworking.sharedInstance.sendMove(array)
            for i in bubbles {
                i.arrowPoint = ccp(0,0)
            }
            lbWaiting.visible = true
        }

    }
    
    func playerStop(){
        GameNetworking.sharedInstance.sendGameEnd(true)
        
    }
    
    func launchBubbles(){
        lbWaiting.visible = false
        for bubble in allBubbles {
            bubble.launch()
        }
        for i in 0...opponentBubbles.count-1 {
            opponentBubbles[i].arrowPoint = ccp(0,0)
        }
    }
    
    func matchEnded(){
    
    }
    
    func gameOver(player1won: Bool){
        
    }
    func replayReceived (replay: [Double : [[Float]]]){
        lbWaiting.visible = false
        for bubble in bubbles {
            bubble.removeArrow()
        }
        self.replay = replay
        self.replayKeys = self.replay.keys.array as [Double]
        self.replayKeys.sort(<)
        self.lapse = 0
        self.nextRecordPos = 0
        self.isReplaying = true
    }
    
    func initBoard(){
        self.score1.string = String(GameNetworking.sharedInstance.score[0])
        self.score2.string = String(GameNetworking.sharedInstance.score[1])
        
        self.paused = true
        self.showGoal()
        elementMoving = 0
        isRecording = false
        GameNetworking.sharedInstance.sendReplay(replay)
        elementMoving = 0
    }
    
    func showGoal() {
        lbGoal.visible = true
    }
    
    func moveReceived(points: [Float]){
        
        for i in 0...opponentBubbles.count-1 {
            opponentBubbles[i].arrowPoint = ccp(CGFloat(points[i*2]), CGFloat(points[i*2+1]))
        }
        /*
        bubble1.arrowPoint = ccp(CGFloat(points[0]), CGFloat(points[1]))
        bubble2.arrowPoint = ccp(CGFloat(points[2]), CGFloat(points[3]))
        bubble3.arrowPoint = ccp(CGFloat(points[4]), CGFloat(points[5]))
        */
        /*for bubble in bubbles {
            bubble.launch()
        }*/
        
        /*bubble1.position = ccp(CGFloat(points[0]), CGFloat(points[1]))
        bubble2.position = ccp(CGFloat(points[2]), CGFloat(points[3]))
        bubble3.position = ccp(CGFloat(points[4]), CGFloat(points[5]))
        ball.position = ccp(CGFloat(points[6]), CGFloat(points[7]))*/
        //println("\(points[0]) \(points[1]) \(points[2]) \(points[3]) \(points[4]) \(points[5]) \(points[6]) \(points[7])")
    }
    
    func ready(){
        
        if lbGoal.visible {
            for bubble in allBubbles {
                bubble.initState()
            }
            ball.initState()
            self.paused = false
            lbGoal.visible = false
            
        }else{
            lbWaiting.visible = false
        }
        
    }
    
    func scoreReceived(scoreChanged: Bool){
        
        if scoreChanged {
            self.score1.string = String(GameNetworking.sharedInstance.score[0])
            self.score2.string = String(GameNetworking.sharedInstance.score[1])
            for bubble in allBubbles {
                bubble.initState()
            }
            ball.initState()
            lbGoal.visible = true
            NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("hideGoal"), userInfo: nil, repeats: false)
        }
    }
    
    func hideGoal() {
        lbGoal.visible = false
    }
    
    
    
    func bubbleUpdateStatus(isMoving: Bool) {
        if isMoving {
            elementMoving++
            if !isRecording {
                replay = [:]
                lapse = 0.0
                nextRecord = 0.0
                isRecording = true
            }
        }else{
            elementMoving--
            if elementMoving == 0 {
                isRecording = false
                
                GameNetworking.sharedInstance.sendReplay(replay)
                lbWaiting.visible = true
            }
        }
    }
    
    func recordMove(key: Double){
        var arTotal: [[Float]] = []
        for bubble in bubbles {
            arTotal.append([ Float(bubble.position.x), Float(bubble.position.y), bubble.rotation])
        }
        for bubble in opponentBubbles {
            arTotal.append([ Float(bubble.position.x), Float(bubble.position.y), bubble.rotation])
        }
        
        arTotal.append([ Float(ball.position.x), Float(ball.position.y), ball.rotation])
        
        replay[key] = arTotal
        
    }
    
    func showMove (move: [[Float]]) {
        for i in 0...bubbles.count-1 {
            bubbles[i].position = ccp(CGFloat(move[i+3][0]), CGFloat(move[i+3][1]))
            //println(allBubbles[i].position)
            bubbles[i].rotation = move[i+3][2]
            //println(allBubbles[i].rotation)
        }
        
        for i in 0...opponentBubbles.count-1 {
            opponentBubbles[i].position = ccp(CGFloat(move[i][0]), CGFloat(move[i][1]))
            //println(allBubbles[i].position)
            opponentBubbles[i].rotation = move[i][2]
            //println(allBubbles[i].rotation)
        }
        
        ball.position = ccp(CGFloat(move[6][0]), CGFloat(move[6][1]))
        //ball.rotation = move[6][2]
    }
    
    override func update(delta: CCTime) {
        
        if isRecording{
            lapse += delta
            if lapse >= nextRecord {
                nextRecord += 0.025
                self.recordMove(lapse)
            }
            
        }
        
        if isReplaying {
            lapse += delta
            if lapse >= replayKeys[nextRecordPos] {
                self.showMove(replay[replayKeys[nextRecordPos]]!)
                if nextRecordPos+1 > replayKeys.count-1 {
                    isReplaying = false
                    GameNetworking.sharedInstance.sendReadyNextMove()
                }
                else {nextRecordPos++}
            }
        }
        
        /*if bubble1.isMoving() || bubble2.isMoving() || bubble3.isMoving() || ball.isMoving() {
            let ar = [Float(bubble1.position.x), Float(bubble1.position.y), Float(bubble2.position.x), Float(bubble2.position.y), Float(bubble3.position.x), Float(bubble3.position.y), Float(ball.position.x), Float(ball.position.y)]
            GameNetworking.sharedInstance.sendMove(ar)
        }*/
    }
}
