//
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation
import CoreGraphics
import SpriteKit

func==(rhs:L8RSKItem, lhs:L8RSKItem) -> Bool {
    return rhs.item == lhs.item
}

class L8RSKItem : SKSpriteNode {
    var date:NSDate! {
        return item.createdDate
    }
    
    //item <-> nodeitem relationship is immutable, only one nodeitem related to one item at a time
    let item:L8RItem
    
    var text:String! {
        get {
            return self.item.text
        }
        set {
            self.item.text = newValue
            textUpdated()
        }
    }
    var textNode:SKLabelNode!
    
    init(item: L8RItem, color:SKColor, size:CGSize) {
        self.item = item
        super.init(texture: nil, color: color, size: size)
        
        self.name = "L8RSKItemNode: date = \(self.date)"
        
        if item.hasImage {
            item.loadImage() { (image) -> Void in
                if image != nil {
                    NSThread.dispatchAsyncOnMainQueue() {
                        self.texture = SKTexture(image: image)
                    }
                }
                
            }
        }
        
        itemUpdated()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func itemUpdated() {
        self.textUpdated()
    }
    
    private func textUpdated() {
        NSThread.dispatchAsyncOnMainQueue() {
            
            if self.item.text == nil && self.textNode != nil {
                self.textNode.removeFromParent()
                self.textNode = nil
                return
            }
            else if self.item.text != nil && self.textNode == nil {
                self.textNode = SKLabelNode(text: self.item.text)
                self.textNode.position = CGPoint(x: 0, y: 0)
                self.textNode.fontSize = 20
                self.textNode.fontName = "San Francisco-Bold"
                self.textNode.fontColor = SKColor.blackColor()
                self.addChild(self.textNode)
                return

            }

            self.textNode.text = self.item.text
            
        }
    }
    
}
