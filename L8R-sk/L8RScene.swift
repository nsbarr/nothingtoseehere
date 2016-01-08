//
//  Copyright (c) 2016 poemsio. All rights reserved.
//

import SpriteKit
import AVFoundation

class L8RScene: SKScene, UIGestureRecognizerDelegate {

    //iPhone 6
    var scale: CGFloat!
    
    var l8rScroller: L8RSKScrollerNode!
    var l8rItemSet: L8RItemSet!
    
    var backgroundNode:SKNode!
    
    var photoCameraController:PhotoCameraController!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.whiteColor()
        self.scaleMode = .AspectFill

        
//        self.scale = self.size.width / 320.0
        
//        NSLog("SZ = \(self.size)")
        self.l8rScroller = L8RSKScrollerNode(size: self.size)
        self.l8rScroller.position = self.size.center
        self.l8rScroller.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        self.addChild(self.l8rScroller)
        
        self.l8rScroller!.l8rCreatorNode.takePhotoAction = { [weak self] () -> Void in
            self?.takePhoto()
        }
        
        var start = NSDate().timeIntervalSince1970
        let secInDay:NSTimeInterval = 86400
        start = start - (secInDay*4)
        
        NSLog("L8RScene created")

    }
    
    func takePhoto() {
        if let photoController = self.photoCameraController {
            photoController.takePhoto({ (image, metadata) -> Void in
                NSLog("photoController.takePhoto callback received, image size: \(image?.size)")
                if let im = image {
                    self.l8rItemSet?.createItemWithImage(im, metadata: metadata)
                }
                
            })
        }
    }
    
    func loadItems(itemSet:L8RItemSet) {
        l8rItemSet = itemSet
        l8rItemSet.itemCreatedCallback = { [weak self] (item:L8RItem, image:UIImage?) -> Void in
            self?.l8rScroller?.addItem(item, image: image, animate: true)
        }
        for item in itemSet.allItemsSortedByDate {
            self.l8rScroller.addItem(item)
        }
    }
    
    
    func returnToToday() {
        
        self.l8rScroller.scrollToToday()
    }
    
    
    func testScrolling() {
        var count = 0
        let items = l8rItemSet.allItemsSortedByDate
        delay(5) {
            for item in items {
                delay(NSTimeInterval(count * 2)) {
                    self.l8rScroller.scrollToItem(item)
                }
                count++
            }
        }
        let todayItems = l8rItemSet.itemsForToday
        if todayItems.count > 0 {
            delay(NSTimeInterval(items.count * 2 + 2)) {
                self.l8rScroller.scrollToItem(todayItems.first!)
            }
        }
    }
    
    override func didMoveToView(view: SKView) {
        
        view.addSwipeGestureRecognizer(UISwipeGestureRecognizer(target: self, action: "swipeGesture:"), direction: .Left)
        view.addSwipeGestureRecognizer(UISwipeGestureRecognizer(target: self, action: "swipeGesture:"), direction: .Right)

        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "longPressGesture:")
        longPressRecognizer.minimumPressDuration = 0.25
        view.addGestureRecognizer(longPressRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapGesture:")
        view.addGestureRecognizer(tapRecognizer)


    }
    
    func tapGesture(recognizer:UITapGestureRecognizer) {
        if recognizer.state == .Ended {
            let pv = recognizer.locationInView(view)
            let position = scene!.convertPointFromView(pv)
            let intersectingNodes = scene!.nodesAtPoint(position)
//            dump(intersectingNodes)
            for node in intersectingNodes {
                if node.reactsToTap {
                    let nodePosition = self.convertPoint(position, toNode: node)
                    //if gesture was 'consumed', return
                    if node.processTap(atPosition:nodePosition, recognizer:recognizer) {
                        return
                    }
                }
            }

            
        }
    }
    
    var longPressPreviousPosition:CGPoint!
    var longPressOriginalScrollerPosition:CGPoint!
    
    func longPressGesture(gesture:UILongPressGestureRecognizer) {
        
        if gesture.state == .Began {
            longPressPreviousPosition = gesture.locationInView(view)
            longPressOriginalScrollerPosition = self.l8rScroller.position
        }
        else if gesture.state == .Changed {
            let newPos = gesture.locationInView(view)
            let difX = newPos.x - longPressPreviousPosition.x

            if difX != 0 {
                self.l8rScroller.adjustPositionXBy(difX)
            }
            
            longPressPreviousPosition = newPos
            
        }
        else if gesture.state == .Ended {
            longPressPreviousPosition = nil
            let action = SKAction.moveTo(longPressOriginalScrollerPosition, duration: 0.5)
            action.timingMode = SKActionTimingMode.EaseOut
            self.l8rScroller.runAction(action)
            longPressOriginalScrollerPosition = nil
        }
       
    }
    
    func swipeGesture(rec:UISwipeGestureRecognizer) {
//        let location = touch.locationInNode(self)
//        let prevLocation = touch.previousLocationInNode(self)
        var difX:CGFloat = 0
        if rec.direction == .Left {
            difX = -self.l8rScroller.swipeIncrement
        }
        else if rec.direction == .Right {
            difX = self.l8rScroller.swipeIncrement
        }
        
        if difX != 0 {
            let act = SKAction.moveBy(CGVector(dx: difX, dy: 0), duration: 0.25)
            act.timingMode = .EaseIn
            self.l8rScroller.runAction(act)
        }
    }
    
    var lastUpdate:NSTimeInterval = 0
    var isUpdatingCameraFrame:Bool = false
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        let time = CACurrentMediaTime()
        
        if (time - lastUpdate) > (1.0/30.0) { //this is processed up to 30 times per second
            lastUpdate = time
            if self.photoCameraController != nil && self.l8rScroller?.l8rCreatorNode != nil && self.photoCameraController.hasFrameData {
                self.photoCameraController.retrieveLastFrame({ (image, size) -> Void in
                    self.l8rScroller.l8rCreatorNode.updateCameraFrame(image, size: size)
                })
            }
        }
    }
    
    
    
}
