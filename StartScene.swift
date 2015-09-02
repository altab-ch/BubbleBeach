//
//  StartScene.swift
//  BubbleBeach
//
//  Created by Mathieu Knecht on 16.07.15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

import Foundation
import GameKit

class StartScene: CCNode {
    
    func didLoadFromCCB() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("presentAuthenticationViewController"), name: "PresentAuthenticationViewController", object: nil)
        if DeviceType.IS_IPHONE_4_OR_LESS {
            self.position = ccp (-47,0)
        }
        GameKitManager.sharedInstance.authenticateLocalPlayer()
    }
    
    func presentAuthenticationViewController(){
        if let vc = GameKitManager.sharedInstance.authenticationVC{
            CCDirector.sharedDirector().presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func startGame(){
        GameNetworking.sharedInstance.findMatch()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}