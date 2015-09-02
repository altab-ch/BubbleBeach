//
//  GameNetworking.swift
//  BubbleBeach
//
//  Created by Mathieu Knecht on 18.07.15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

import Foundation
import GameKit

protocol GameNetworkingDelegate{
    func matchEnded()
    func gameOver(player1won: Bool)
    func moveReceived(points: [Float])
    func replayReceived (replay: [Double : [[Float]]])
    func ready()
    func scoreReceived(scoreChanged: Bool)
    func launchBubbles()
    func initBoard()
}

enum MessageType: Int {
    case kMessageTypeGameOver = 0, kMessageTypeGameBegin = 1, kMessageTypeMove = 2, kMessageTypeReadyNextMove = 3, kMessageTypeScore = 4
}

struct Message{
    var message: MessageType
}

struct MessageGameOver {
    var message: Message
    var player1won: Bool
}

struct MessageScore {
    var message: Message
    var score1: Float
    var score2: Float
}

struct MessageMove {
    var message: Message
    var b1x: Float
    var b1y: Float
    var b2x: Float
    var b2y: Float
    var b3x: Float
    var b3y: Float
}


class GameNetworking: NSObject, GameCenterDelegate {
    
    static let sharedInstance = GameNetworking()
    
    var opponentArrow: CGPoint?
    var hasReceivedData = false
    var isReady = false
    var networkDelegate: GameNetworkingDelegate?
    var is1stPlayer = false
    var score: [Int] = [0,0]
    
    func matchStarted(is1stPlayer: Bool){
        self.is1stPlayer = is1stPlayer
        score = [0,0]
        hasReceivedData = false
        isReady = false
        let mainScene = CCBReader.loadAsScene("MainScene")
        if let scene = mainScene.children[0] as? MainScene {
            self.networkDelegate = scene
            if DeviceType.IS_IPHONE_4_OR_LESS {
                scene.position = ccp (-47,0)
            }
            
        }
        CCDirector.sharedDirector().replaceScene(mainScene)
    }
    
    func matchEnded(){
        /*if let del = networkDelegate{
            del.matchEnded()
        }*/
        
        let startScene = CCBReader.loadAsScene("StartScene")
        CCDirector.sharedDirector().replaceScene(startScene)
    }
    
    func match(match: GKMatch!, didReceiveData data: NSData!, fromRemotePlayer player: GKPlayer!){
        
        if data.length > 128 {
            if let replay = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [Double : [[Float]]]{
                networkDelegate?.replayReceived(replay)
            }
        }else{
            if let message: Message = decode(data){
                switch message.message {
                case .kMessageTypeGameOver:
                    println("Game over received")
                    var overMessage: MessageGameOver = decode(data)
                    //networkDelegate?.gameOver(overMessage.player1won)
                    self.matchEnded()
                case .kMessageTypeMove:
                    println("Move received")
                    var moM: MessageMove = decode(data)
                    self.hasReceivedData = true
                    self.networkDelegate?.moveReceived([moM.b1x, moM.b1y, moM.b2x, moM.b2y, moM.b3x, moM.b3y])
                    if isReady {
                        self.launchBubble()
                    }else{
                        self.hasReceivedData = true
                    }
                case .kMessageTypeGameBegin:
                    println("Game begin received")
                case .kMessageTypeReadyNextMove:// ready 2nd
                    var moM = MessageScore(message: Message(message: MessageType.kMessageTypeScore), score1: Float(score[0]), score2: Float(score[1]))
                    let data = self.encode(moM)
                    self.sendData(data)
                    networkDelegate?.ready()
                case .kMessageTypeScore:// ready 1st
                    var moM: MessageScore = decode(data)
                    let hasChanged = self.score[0] != Int(moM.score1) || self.score[1] != Int(moM.score2)
                    self.score = [Int(moM.score1), Int(moM.score2)]
                    println(moM.score1)
                    println(moM.score2)
                    networkDelegate?.scoreReceived(hasChanged)
                default:
                    println("Bad command received")
                }
            }
        }
        
    }
    
    func launchBubble() {
        self.isReady = false
        self.hasReceivedData = false
        networkDelegate?.launchBubbles()
    }
    
    func ready(){
        self.isReady = true
        if hasReceivedData {
            self.launchBubble()
        }
    }
    
    func findMatch (){
        GameKitManager.sharedInstance.findMatch(2, maxPlayers: 2, viewController: CCDirector.sharedDirector(), delegate: self)
    }
    
    func sendData (data: NSData!){
        var error: NSError?
        if let match = GameKitManager.sharedInstance.match {
            if !match.sendDataToAllPlayers(data, withDataMode: GKMatchSendDataMode.Reliable, error: &error){
                println("Error sending data \(error?.localizedDescription)")
                self.matchEnded()
            }
            
        }
    }
    
    func sendGameEnd(player1won: Bool){
        var message = MessageGameOver(message: Message(message: MessageType.kMessageTypeGameOver), player1won: player1won)
        let data = self.encode(message)
        self.sendData(data)
        self.matchEnded()
    }
    
    func sendMove(points: [Float]){
        var message:MessageMove = MessageMove(message: Message(message: MessageType.kMessageTypeMove), b1x: points[0], b1y: points[1], b2x: points[2], b2y: points[3], b3x: points[4], b3y: points[5])
        let data = self.encode(message)
        self.sendData(data)
    }
    
    func sendReplay(replay: [Double : [[Float]]]){
        let ddata = NSKeyedArchiver.archivedDataWithRootObject(replay)
        self.sendData(ddata)
    }
    
    func sendReadyNextMove(){
        var message:Message = Message(message: MessageType.kMessageTypeReadyNextMove)
        let data = self.encode(message)
        self.sendData(data)
    }
    
    func encode<T>(var value: T) -> NSData {
        return withUnsafePointer(&value) { p in
            NSData(bytes: p, length: sizeofValue(value))
        }
    }
    
    func decode<T>(data: NSData) -> T {
        let pointer = UnsafeMutablePointer<T>.alloc(sizeof(T))
        data.getBytes(pointer, length: sizeof(T))
        
        return pointer.move()
    }
    
    func playerScore (firstPlayerScored: Bool){
        score = firstPlayerScored ? [score[0]+1, score[1]]:[score[0], score[1]+1]
        self.initBoard()
    }
    
    func initBoard () {
        networkDelegate?.initBoard()
    }
    
}