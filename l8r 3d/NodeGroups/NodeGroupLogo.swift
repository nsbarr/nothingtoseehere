//
//  Copyright (c) 2015 The Web Electric Corp. All rights reserved.
//

import Foundation
import SpriteKit
import SceneKit
import J58


public class NodeGroupLogo : SCNNodeGroup {
    
    
    override public func didPrepare() {
        self.cameraDidArriveAction = {
            NSThread.dispatchAsyncOnMainQueue() {
                AppEvents.fireAction(AppEventKey.VisitLocation, eventInfo: ["name":"l8rBox", "animationDuration": NSTimeInterval(4)])
            }
            
                    }
        
        
        
    }

    
    override public func didLoad() {
        NSThread.dispatchAsyncOnMainQueue() {
//            if let logoIcon = self.childNodeWithName("logo_icon", recursively: true) {
//                NSLog("playing sound on icon")
//                logoIcon.attachSound(named: "440Hz_44100Hz_16bit_30sec.mp3", volume: 1, positional: true)
//            }
        }
        
    }
//
//    override public func unloadContents() {
//
//    }
}
