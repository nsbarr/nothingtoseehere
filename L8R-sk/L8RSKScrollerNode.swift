//
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation
import CoreGraphics
import SpriteKit
import AVFoundation
import CoreImage

class L8RSKScrollerNode : SKSpriteNode {
    
    var l8rCreatorNode: CreateL8RSKNode!
    var nodeOverCreatorNode:SKNode!
    var dateToStackMap:[String: L8RSKItemStack] = [String:L8RSKItemStack]()
    var sortedStacks:[L8RSKItemStack] {
        var stacks = Array(dateToStackMap.values)
        stacks.sortInPlace({ (e1, e2) -> Bool in
            //oldest date first
            return e1.date < e2.date
        })
        return stacks
    }
    
    var baseWidth:CGFloat
    var l8rCreatorNodeBaseSize:CGSize!
    
    var swipeIncrement:CGFloat {
        return self.baseWidth
    }
    
    init(size:CGSize) {
        self.baseWidth = size.width
        super.init(texture:nil, color: SKColor.blueColor(), size: CGSize(width: self.baseWidth*3, height: size.height))
        self.name = "L8RSKScrollerNode"

        let creatorNodeLeftMargin:CGFloat = 60
        self.l8rCreatorNode = CreateL8RSKNode(size: CGSize(width: self.baseWidth-creatorNodeLeftMargin, height: self.height-creatorNodeLeftMargin))
        l8rCreatorNodeBaseSize = l8rCreatorNode.size
        self.l8rCreatorNode.position = self.size.center
        self.l8rCreatorNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)


        self.addChild(self.l8rCreatorNode)

        //TODO fix undetermined behavior when the app is open and the day rolls over to the next day
        nodeOverCreatorNode = self.stackForDate(NSDate())
        nodeOverCreatorNode.zPosition = 1

        self.l8rCreatorNode.position = positionForToday()
        self.l8rCreatorNode.adjustPositionXBy(40)
        self.l8rCreatorNode.adjustPositionYBy(-40)
        self.l8rCreatorNode.zPosition = 2
    }
    
    override var reactsToTap:Bool {
        return true
    }
    
    ///returns true if consumed, false otherwise
    override func processTap(atPosition position:CGPoint, recognizer:UITapGestureRecognizer) -> Bool {
        let creatorNodeHit = l8rCreatorNode.containsPoint(position)
        let otherNodeHit = nodeOverCreatorNode.containsPoint(position)
        let creatorNodeOnTop = l8rCreatorNode.zPosition == 2
        if creatorNodeOnTop && (creatorNodeHit || otherNodeHit) {
            //send back
            moveCreatorNodeToBack()
            return true
        }
        else if !creatorNodeOnTop && (creatorNodeHit || otherNodeHit) {
            //special case to make a double tap 'reversible'
            moveCreatorNodeToFront()
            return true
        }

        return false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func moveCreatorNodeToFront() {
        moveCreatorNodeToZPosition(2)
    }

    func moveCreatorNodeToBack() {
        moveCreatorNodeToZPosition(0)
    }

    private func moveCreatorNodeToZPosition(zPos:CGFloat) {
        let moveOutAction = SKAction.moveByX(l8rCreatorNode.width*2/3, y: l8rCreatorNode.height*2/3, duration: 0.25)
        moveOutAction.timingMode = SKActionTimingMode.EaseIn
        let changeZAction = SKAction.runBlock { () -> Void in
            NSThread.dispatchSyncOnMainQueue() {
            self.l8rCreatorNode.zPosition = zPos
            }
        }
        let moveBack = SKAction.moveByX(-l8rCreatorNode.width*2/3, y: -l8rCreatorNode.height*2/3, duration: 0.25)
        moveBack.timingMode = SKActionTimingMode.EaseIn
        
        l8rCreatorNode.runAction(SKAction.sequence([moveOutAction, changeZAction, moveBack]))
        
        
    }
    
    func positionForToday() -> CGPoint {
        let dateKey = NSDate().yyyyMMddKey
        return dateToStackMap[dateKey]!.position
    }
    
    func scrollToToday() {
        //TODO fix undetermined behavior when the app is open and the day rolls over to the next day
        scrollToDate(NSDate())
    }

    func scrollToItem(item: L8RItem, completion: (() -> Void)! = nil) {
        self.scrollToDate(item.createdDate, completion: completion)
    }

    func scrollToDate(date: NSDate, completion: (() -> Void)! = nil) {
        let dateKey = date.yyyyMMddKey
        if let stackForItem = dateToStackMap[dateKey] {
            let pos = -stackForItem.x + (self.baseWidth/2)
            
            let moveAction = SKAction.moveTo(CGPoint(x: pos, y: self.position.y), duration: 1)
            moveAction.timingMode = SKActionTimingMode.EaseIn
            
            self.runAction(moveAction, completion: { () -> Void in
                
                if completion != nil {
                    completion()
                }
                
            })
        }
    }
    
    func addItem(item:L8RItem, image:UIImage? = nil, animate:Bool = false) -> L8RSKItem {
        let devSz = CGSize(width: self.baseWidth, height: self.height)
        let w:CGFloat = devSz.width-(20*2)
        let h = devSz.height-(20*2)
        let size = CGSize(width: w, height: h)

        
        let item = L8RSKItem(item: item, color: SKColor.redColor(), size: size, image: image)

        let stack = self.stackForDate(item.date)

        if animate {
            //this is when a new L8R's been created and we animate that from the creator node 
            //to the stack
            item.alpha = 0
            stack.addItem(item)
            self.moveCreatorNodeToBack()
            item.flashFadeIn()
        }
        else {
            stack.addItem(item)
    //        item.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    //        item.position = stack.size.center
            var bw = self.dateToStackMap.count.cgf * self.baseWidth
            if bw < (self.baseWidth * 3) {
                bw = self.baseWidth * 3
            }
            self.size = CGSize(width: bw, height: self.size.height)
        }
        
        return item
        
    }
    
    func xPositionForStack(stack:L8RSKItemStack) -> CGFloat {
        let totalSz = sortedStacks.count.cgf * self.baseWidth
        
        for i in 0..<sortedStacks.count {
            if sortedStacks[i] == stack {
                return (CGFloat(i) * self.baseWidth) + (self.baseWidth/2) - (totalSz/2)
            }
        }
        return -(self.size.width)-self.baseWidth
    }
   
    func stackForDate(date:NSDate) -> L8RSKItemStack {
        var stack:L8RSKItemStack! = self.dateToStackMap[date.yyyyMMddKey]
        if stack == nil {
            let devSz = CGSize(width: self.baseWidth, height: self.height)
            let w:CGFloat = devSz.width-(10*2)
            let h = devSz.height-(10*2)
            let size = CGSize(width: w, height: h)
            
            stack = L8RSKItemStack(date: date, size: size)

            stack.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            self.dateToStackMap[date.yyyyMMddKey] = stack
            var xPosition = -((sortedStacks.count.cgf * self.baseWidth)/2) + (self.baseWidth/2)
            for stack in sortedStacks {
                stack.x = xPosition
                xPosition += self.baseWidth
            }
            NSThread.dispatchSyncOnMainQueue() {
                self.addChild(stack)
            }

        }
        return stack
    }
}