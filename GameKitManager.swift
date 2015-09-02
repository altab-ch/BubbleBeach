//
//  GameKitManager.swift
//  BubbleBeach
//
//  Created by Mathieu Knecht on 17.07.15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

import Foundation
import GameKit

protocol GameCenterDelegate {
    func matchStarted(is1stPlayer: Bool)
    func matchEnded()
    func match(match: GKMatch!, didReceiveData data: NSData!, fromRemotePlayer player: GKPlayer!)
}

class GameKitManager: NSObject, GKMatchmakerViewControllerDelegate, GKMatchDelegate {
    static let sharedInstance = GameKitManager()
    
    var match : GKMatch?
    var matchDelegate : GameCenterDelegate?
    
    var authenticationVC : UIViewController?
    var gcEnabled = false
    var matchStarted = false
    var playerDict: [String:GKPlayer] = [:]
    
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1 Show login if player is not logged in
                self.authenticationVC = ViewController
                NSNotificationCenter.defaultCenter().postNotificationName("PresentAuthenticationViewController", object: nil)
            } else if (localPlayer.authenticated) {
                // 2 Player is already euthenticated & logged in, load game center
                self.gcEnabled = true
                
                
            } else {
                // 3 Game center is not enabled on the users device
                self.gcEnabled = false
                println("Local player could not be authenticated, disabling game center")
                println(error)
            }
            
        }
        
    }
    
    func lookupPlayers (){
        println("Looking up \(match?.playerIDs.count) players...")
        GKPlayer.loadPlayersForIdentifiers(match?.playerIDs, withCompletionHandler: { (players, error) -> Void in
            if error == nil {
                if let players = players as? [GKPlayer] {
                    for player in players {
                        self.playerDict[player.playerID] = player
                    }
                    self.playerDict[GKLocalPlayer.localPlayer().playerID] = GKLocalPlayer.localPlayer()
                    self.matchStarted = true
                    let is1st = GKLocalPlayer.localPlayer().playerID > players[0].playerID
                    self.matchDelegate?.matchStarted(is1st)
                }
            }else{
                self.matchStarted = false
                self.matchDelegate?.matchEnded()
            }
        })
        
    }
    
    func findMatch(minPlayers:Int, maxPlayers:Int, viewController: UIViewController, delegate:GameCenterDelegate) {
        
        if (!gcEnabled) {return}
        
        matchStarted = false
        self.match = nil
        matchDelegate = delegate
        
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        
        let mmvc = GKMatchmakerViewController(matchRequest: request)
        mmvc.matchmakerDelegate = self
        
        viewController.presentViewController(mmvc, animated: true, completion: nil)
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFindMatch match: GKMatch!) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
        self.match = match
        match.delegate = self
        if (!matchStarted && match.expectedPlayerCount == 0) {
            println("Ready to start match!")
            self.lookupPlayers()
        }
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFindHostedPlayers players: [AnyObject]!) {
        
    }
    
    
    func matchmakerViewControllerWasCancelled(viewController: GKMatchmakerViewController!) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFailWithError error: NSError!) {
        
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController!, hostedPlayerDidAccept player: GKPlayer!) {
        
    }
    
    func match(match: GKMatch!, didReceiveData data: NSData!, fromRemotePlayer player: GKPlayer!) {
        matchDelegate?.match(match, didReceiveData: data, fromRemotePlayer: player)
    }
    
    func match(match: GKMatch!, player: GKPlayer!, didChangeConnectionState state: GKPlayerConnectionState) {
        
    }
    
    func match(match: GKMatch!, shouldReinviteDisconnectedPlayer player: GKPlayer!) -> Bool {
        return false
    }
    
    
}