//
//  Copyright (c) 2015 The Web Electric Corp. All rights reserved.
//

import Foundation
import SpriteKit
import SceneKit
import J58


class ContainerWallNode: SCNNode, NXNodeEventHandler {
    var actionEnabled:Bool = true
    
    var acceptsPanEvents:Bool  = false
    var acceptsSwipeEvents:Bool  = false
    var acceptsTapEvents:Bool  = true
    var acceptsDoubleTapEvents:Bool  = false
    
    var eventKey:NXAppEventKey
    var eventAction:NXAppEventAction

    init(originalWallNode:SCNNode, eventKey:NXAppEventKey, action:NXAppEventAction) {
        self.eventKey = eventKey
        self.eventAction = action
        super.init()
        self.takeOverForNode(originalWallNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func node(aNode:SCNNode, didReceiveTapEventAt localCoordinates:SCNVector3, eventPoint:CGPoint) -> Bool {
        NSLog("tapped: \(self.name!)")
        
        NXAppEvents.fireAction(self.eventKey, action: self.eventAction)
        
        return true
    }
    

    func node(aNode:SCNNode, didReceivePanEventAt localCoordinates:SCNVector3, eventPoint:CGPoint, withDelta delta:CGPoint) -> Bool {
        return false
    }
    func node(aNode:SCNNode, didReceiveSwipeEventAt localCoordinates:SCNVector3, eventPoint point:CGPoint, withDelta delta:CGPoint) -> Bool {
        return false
    }
    func node(aNode:SCNNode, didReceiveDoubleTapEventAt localCoordinates:SCNVector3, eventPoint:CGPoint) -> Bool {
        return false
    }

}


public class NodeGroupL8RBox : NXNodeGroup, AppEventListener {
    let _listenerKey:String = String.createUUIDString()!
    public var listenerKey:String { return _listenerKey }
    
    var wallFocusController:L8RWallFocusController!
    
    var photoCameraController:PhotoCameraController!
    
    var l8rsWall:ContainerWallNode!
    var snoozedWall:ContainerWallNode!
    var archivedWall:ContainerWallNode!
    var viewfinderWall:SCNNode!
    
    public func appEventGetRequested<T>(event:NXGetAttributeEvent<T>) -> AnyObject? {
        return nil
    }
    
    public func appEventSetRequested<T>(key: NXAppEventKey, value: T) {
    }
    
    public func appEventTriggered(event:NXAppEvent) {
        
    }
    
    public override func didPrepare() {
        
        NXAppEvents.registerAction(self, forEvent: NXAppEventKey.VisitLocation)

        self.cameraWillDepartAction = {
            NXAppEvents.deregisterAction(self)
        }
        
        self.cameraWillArriveAction = {
//            NXAppEvents.fireAction(WorldEvent(updateFloorReflectivityTo: CGFloat(0)))
        }
        
        self.cameraDidArriveAction = {
            
            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(0.5)
            SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn))
            self.opacity = 1
            SCNTransaction.commit()
            
            NSThread.dispatchAsyncOnMainQueue() {
                self.photoCameraController = PhotoCameraController()
                self.photoCameraController.checkCameraAccess({ (accessGranted) -> Void in
                    // If permission hasn't been granted, notify the user.
                    if !accessGranted {
                        NSThread.dispatchAsyncOnMainQueue() {
                            
                            let info = ["message" : "L8R needs access to the camera, please check your privacy settings.",
                            "title":"Could not use camera!", "actionButton": "OK."]
                            
                            NXAppEvents.fireAction(NXAppEventKey.ShowAlert, eventInfo: info)
                        }
                    }
                    else {
                        self.photoCameraController.prepareCamera()
                    }
                })
            }

        }
    }
    
    deinit {
        self.photoCameraController.teardownCamera()
        self.photoCameraController = nil
    }

    

    override public func didLoad() {
        self.acceptsPanEvents = true
        self.actionEnabled = true
        self.needsFrameUpdates = true

        let camerasNode = self["cameras"]
        self.wallFocusController = L8RWallFocusController(camerasNode: camerasNode!)

        self.l8rsWall = ContainerWallNode(originalWallNode: self["l8rs_wall"]!, eventKey: NXAppEventKey.L8RItems, action: .View)
        self.snoozedWall = ContainerWallNode(originalWallNode: self["snoozed_wall"]!, eventKey: NXAppEventKey.L8RSnoozed, action: .View)
        self.archivedWall = ContainerWallNode(originalWallNode: self["archived_wall"]!, eventKey: NXAppEventKey.L8RArchived, action: .View)
        self.viewfinderWall = self["viewfinder_wall"]!

    }
    
    func updateCameraWall(image:SKTexture?) {
        if let texture = image {
            self.viewfinderWall.diffuseContents = texture
        }
    }
    
    func takePhoto() {
//        if let photoController = self.photoCameraController {
//            photoController.takePhoto({ (image, metadata) -> Void in
//                NSLog("photoController.takePhoto callback received, image size: \(image?.size)")
//                if let im = image {
//                    self.l8rItemSet?.createItemWithImage(im, metadata: metadata)
//                }
//                
//            })
//        }
    }

    var lastUpdate:NSTimeInterval = 0
    var isUpdatingCameraFrame:Bool = false
    
    override public func update(currentTime: NSTimeInterval) {
        /* Called before each frame is rendered */
        
        if (currentTime - lastUpdate) > (1.0/30.0) { //this is processed up to 30 times per second
            lastUpdate = currentTime
            if self.photoCameraController != nil && self.photoCameraController.hasFrameData {
                self.photoCameraController.retrieveLastFrame({ (image) -> Void in
                    self.updateCameraWall(image)
                })
            }
        }
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
  


}

