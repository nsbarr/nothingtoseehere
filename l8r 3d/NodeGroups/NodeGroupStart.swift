//
//  Copyright (c) 2015 The Web Electric Corp. All rights reserved.
//

import Foundation
import SpriteKit
import SceneKit
import J58


public class NodeGroupStart : SCNNodeGroup {
    
    public override func didPrepare() {
        self.cameraDidArriveAction = {
            NSThread.dispatchAsyncOnMainQueue(afterDelay: 1) {
                AppEvents.fireAction(AppEventKey.VisitLocation, eventInfo: ["name":"logo", "animationDuration": NSTimeInterval(3)])
            }
        }
    }
    
//    override func didLoad() {
//    }
//    
//    override func didUnload() {
//    }
}
