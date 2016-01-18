//
//  Copyright (c) 2015 The Web Electric Corp. All rights reserved.
//

import Foundation
import SpriteKit
import SceneKit
import J58


public extension NXAppEventKey {
    
    public static let L8RItems = NXAppEventKey("L8RItems")
    public static let L8RSnoozed = NXAppEventKey("L8RSnoozed")
    public static let L8RArchived = NXAppEventKey("L8RArchived")
    public static let L8RViewFinder = NXAppEventKey("L8RViewFinder")
    
}


public class L8RWallFocusController : AppEventListener {
    let _listenerKey:String = String.createUUIDString()!
    public var listenerKey:String { return _listenerKey }
    
    var l8rsWallCamera:SCNNode!
    var viewfinderWallCamera:SCNNode!
    var snoozedWallCamera:SCNNode!
    var archivedWallCamera:SCNNode!

    var camerasNode:SCNNode!
    
    public init(camerasNode:SCNNode) {
        
        self.camerasNode = camerasNode
        
        self.l8rsWallCamera = camerasNode["l8rs_wall_cam"]
        self.viewfinderWallCamera = camerasNode["viewfinder_wall_cam"]
        self.snoozedWallCamera = camerasNode["snoozed_wall_cam"]
        self.archivedWallCamera = camerasNode["archived_wall_cam"]

        
        NXAppEvents.registerAction(self, forEvent: NXAppEventKey.L8RItems)
        NXAppEvents.registerAction(self, forEvent: NXAppEventKey.L8RSnoozed)
        NXAppEvents.registerAction(self, forEvent: NXAppEventKey.L8RArchived)
        NXAppEvents.registerAction(self, forEvent: NXAppEventKey.L8RViewFinder)
    }
    
    deinit {
        NXAppEvents.deregisterAction(self)
    }
    
    
    public func appEventGetRequested<T>(event:NXGetAttributeEvent<T>) -> AnyObject? {
        return nil
    }
    
    public func appEventSetRequested<T>(key: NXAppEventKey, value: T) {
    }
    
    public func appEventTriggered(event:NXAppEvent) {
        var tempCameraClone:SCNNode!
        
        switch event.key {
        case NXAppEventKey.L8RItems:
            if event.action == .View {
                tempCameraClone = self.l8rsWallCamera.generateCameraStructureNode().holderNode
                print("Received event: focus on l8rs")
            }
            break
        case NXAppEventKey.L8RSnoozed:
            if event.action == .View {
                tempCameraClone = self.snoozedWallCamera.generateCameraStructureNode().holderNode
                print("Received event: focus on snoozed")
            }
            break
        case NXAppEventKey.L8RArchived:
            if event.action == .View {
                print("Received event: focus on archived")
                tempCameraClone = self.archivedWallCamera.generateCameraStructureNode().holderNode
            }
            break
        case NXAppEventKey.L8RViewFinder:
            if event.action == .View {
                print("Received event: focus on viewfinder")
                tempCameraClone = self.viewfinderWallCamera.generateCameraStructureNode().holderNode
            }
            break
        default:
            break
        }
        self.camerasNode.addChildNode(tempCameraClone)
        let completionBlock = ClosureHolder() {
            
            tempCameraClone.removeFromParentNode()
        }
        
        NXAppEvents.fireAction(NXAppEventKey.NXViewpointMatchCamera, eventInfo: ["cameraNodeToMatch": tempCameraClone, "animationDuration" : NSTimeInterval(0.75), "completion" : completionBlock])

        
    }
}