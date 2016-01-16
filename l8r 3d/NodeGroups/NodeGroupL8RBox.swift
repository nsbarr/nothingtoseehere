//
//  Copyright (c) 2015 The Web Electric Corp. All rights reserved.
//

import Foundation
import SpriteKit
import SceneKit
import J58



public extension AppEventKey {
    
    public static let ViewL8R = AppEventKey("ViewL8R")

    public static let ViewSnoozed = AppEventKey("ViewSnoozed")
    
}



public class NodeGroupL8RBox : SCNNodeGroup, AppEventListener {
    let _listenerKey:String = String.createUUIDString()!
    public var listenerKey:String { return _listenerKey }
    
    public func appEventGetRequested<T>(event:NXGetAttributeEvent<T>) -> AnyObject? {
        return nil
    }
    
    public func appEventSetRequested<T>(key: AppEventKey, value: T) {
    }
    
    public func appEventTriggered(event:AppEvent) {
        
        switch event.key {
        case AppEventKey.ViewL8R:
            if event.action == .Update {
            }
            break
        case AppEventKey.ViewSnoozed:
            break
        default:
            break
        }
        
    }
    
    public override func didPrepare() {
        
        AppEvents.registerAction(self, forEvent: AppEventKey.VisitLocation)

        self.cameraWillDepartAction = {
            AppEvents.deregisterAction(self)
        }
        
        self.cameraWillArriveAction = {
//            AppEvents.fireAction(WorldEvent(updateFloorReflectivityTo: CGFloat(0)))
        }
        
        self.cameraDidArriveAction = {
            
            AppEvents.registerAction(self, forEvent: AppEventKey.ViewL8R)
            AppEvents.registerAction(self, forEvent: AppEventKey.ViewSnoozed)

            
            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(0.5)
            SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn))
            self.opacity = 1
            SCNTransaction.commit()

        }
    }
    
    override public func didLoad() {
        self.acceptsPanEvents = true
        self.acceptsTapEvents = true
        self.actionEnabled = true


        
        let l8rscene =  SCNScene(named: "art.scnassets/l8r.scn")
            
        
        if let dateNavRoot = l8rscene!.rootNode.childNodeWithName("walls", recursively: true) {
            self.addChildNode(dateNavRoot)
        }
    
        
//        AppEvents.fireSet(AppEventKey.WorldFloor, value: floor!)
//        let getEvent = NXGetAttributeEvent<SCNNode>(named: AppEventKey.WorldFloor) { (value) -> Void in
//            value?.geometry = floor?.geometry
//            value!.categoryBitMask = 4
//            value?.hidden = true
//        }
//        AppEvents.fireGet(getEvent)



    }
    

    override public func didUnload() {

    }
    
    //if a class implementing the protocol is not using a particular method they should return nil
    override public func node(aNode:SCNNode, didReceivePanEventAt localCoordinates:SCNVector3, eventPoint:CGPoint, withDelta delta:CGPoint) -> Bool {
        //negative delta.y = mouse drag up, positive delta.y = drag down, negative x = drag left, positive x = drag right
        if delta.y != 0 {
            self.adjustPositionZBy(Float(delta.y))
        }
        return false
    }
    override public func node(aNode:SCNNode, didReceiveTapEventAt localCoordinates:SCNVector3, eventPoint:CGPoint) -> Bool {
        NSLog("tap \(localCoordinates) \(eventPoint) ")
        return false
    }


}

