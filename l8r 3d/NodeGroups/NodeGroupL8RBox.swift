//
//  Copyright (c) 2015 The Web Electric Corp. All rights reserved.
//

import Foundation
import SpriteKit
import SceneKit
import J58



public extension NXAppEventKey {
    
    public static let ViewL8R = NXAppEventKey("ViewL8R")

    public static let ViewSnoozed = NXAppEventKey("ViewSnoozed")
    
}



public class NodeGroupL8RBox : NXNodeGroup, AppEventListener {
    let _listenerKey:String = String.createUUIDString()!
    public var listenerKey:String { return _listenerKey }
    
    public func appEventGetRequested<T>(event:NXGetAttributeEvent<T>) -> AnyObject? {
        return nil
    }
    
    public func appEventSetRequested<T>(key: NXAppEventKey, value: T) {
    }
    
    public func appEventTriggered(event:NXAppEvent) {
        
        switch event.key {
        case NXAppEventKey.ViewL8R:
            if event.action == .Update {
            }
            break
        case NXAppEventKey.ViewSnoozed:
            break
        default:
            break
        }
        
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
            
            NXAppEvents.registerAction(self, forEvent: NXAppEventKey.ViewL8R)
            NXAppEvents.registerAction(self, forEvent: NXAppEventKey.ViewSnoozed)

            
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

    
    var l8rsWall:SCNNode!
    var cameraWall:SCNNode!
    var snoozeWall:SCNNode!
    var archivesWall:SCNNode!
    var photoCameraController:PhotoCameraController!

    override public func didLoad() {
        self.acceptsPanEvents = true
        self.acceptsTapEvents = true
        self.actionEnabled = true
        self.needsFrameUpdates = true


        self.l8rsWall = self["l8rs_wall"]
        self.cameraWall = self["camera_wall"]
        self.snoozeWall = self["archives_wall"]
        self.archivesWall = self["snoozed_wall"]

    }
    
    func updateCameraWall(image:SKTexture?) {
        if let texture = image {
            self.cameraWall.diffuseContents = texture
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
    override public func node(aNode:SCNNode, didReceiveTapEventAt localCoordinates:SCNVector3, eventPoint:CGPoint) -> Bool {
        NSLog("tap \(localCoordinates) \(eventPoint) ")
        return false
    }


}

