//
//  Copyright (c) 2015 The Web Electric Corp. All rights reserved.
//

import Foundation
import SpriteKit
import SceneKit
import J58

public enum L8RWallFocus {
    case Items, Snoozed, Archived, Viewfinder
}

public extension NXAppEventKey {
    
    public static let L8RItems = NXAppEventKey("L8RItems")
    public static let L8RSnoozed = NXAppEventKey("L8RSnoozed")
    public static let L8RArchived = NXAppEventKey("L8RArchived")
    public static let L8RViewFinder = NXAppEventKey("L8RViewFinder")
    
}


public class L8RWallFocusController : AppEventListener {
    let _listenerKey:String = String.createUUIDString()!
    public var listenerKey:String { return _listenerKey }
    
    private (set) public var focusedOn:L8RWallFocus = .Items
    private (set) public var isChangingFocus:Bool = false
    
    
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
        if isChangingFocus {
            return
        }
        isChangingFocus = true
        var newFocus:L8RWallFocus! = nil

        defer {
            //called when method returns 
            if newFocus == nil {
                //if newFocus = nil it means that the focus action was rejected b/c we were
                //already focusing on that wall so we need to change this variable (otherwise
                //it would be changed at the end of the animation)
                isChangingFocus = false
            }
        }
        
        var tempCameraClone:SCNNode!
        switch event.key {
        case NXAppEventKey.L8RItems:
            if event.action == .View {
                if self.focusedOn == .Items {
                    return
                }
                newFocus = .Items
                tempCameraClone = self.l8rsWallCamera.generateCameraStructureNode().holderNode
                print("Received event: focus on l8rs")
            }
            break
        case NXAppEventKey.L8RSnoozed:
            if event.action == .View {
                if self.focusedOn == .Snoozed {
                    return
                }
                newFocus = .Snoozed
                tempCameraClone = self.snoozedWallCamera.generateCameraStructureNode().holderNode
                print("Received event: focus on snoozed")
            }
            break
        case NXAppEventKey.L8RArchived:
            if event.action == .View {
                if self.focusedOn == .Archived {
                    return
                }
                newFocus = .Archived
                print("Received event: focus on archived")
                tempCameraClone = self.archivedWallCamera.generateCameraStructureNode().holderNode
            }
            break
        case NXAppEventKey.L8RViewFinder:
            if event.action == .View {
                if self.focusedOn == .Viewfinder {
                    return
                }
                newFocus = .Viewfinder

                print("Received event: focus on viewfinder")
                tempCameraClone = self.viewfinderWallCamera.generateCameraStructureNode().holderNode
            }
            break
        default:
            break
        }
        self.camerasNode.addChildNode(tempCameraClone)

        let completionBlock = ClosureHolder() {
            self.focusedOn = newFocus
            self.isChangingFocus = false
            tempCameraClone.removeFromParentNode()
        }
        
        NXAppEvents.fireAction(NXAppEventKey.NXViewpointMatchCamera, eventInfo: ["cameraNodeToMatch": tempCameraClone, "animationDuration" : NSTimeInterval(0.75), "completion" : completionBlock])

        
    }
}