//
//  Copyright © 2016 poemsio. All rights reserved.
//


import Foundation
import CoreGraphics
import SpriteKit

func==(lhs:L8RSKItemStack, rhs:L8RSKItemStack) -> Bool {
    return rhs.date.yyyyMMddKey == lhs.date.yyyyMMddKey
}

class L8RSKItemStack : SKSpriteNode {
    var date:NSDate
    var items:[L8RSKItem] = [L8RSKItem]()
    var mainLabel:SKLabelNode!
    var secondaryLabel:SKLabelNode!
    
    override var hashValue:Int {
        return date.yyyyMMddKey.hashValue
    }
    
    init(date:NSDate, size:CGSize) {
        self.date = date
        super.init(texture: nil, color: SKColor.redColor(), size: size)

        self.name = "L8RSKItemStack: date = \(self.date.yyyyMMddKey)"

        mainLabel = SKNode.skLabelWithText("No L8Rs on this day!", atPosition: CGPoint(x: 0, y: 0))
        secondaryLabel = SKNode.skLabelWithText("<wee!>", atPosition: CGPoint(x: 0, y: -30))
        
        self.addChild(mainLabel)
        self.addChild(secondaryLabel)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addItem(item: L8RSKItem) {
        items.append(item)
        addChild(item)
    }
    
    func removeItem(item: L8RSKItem) {
        if let pos = items.indexOf(item) {
            items.removeAtIndex(pos)
            item.removeFromParent()
        }
    }
    
    func showItem(item: L8RSKItem) {
        if self.date.yyyyMMddKey != item.date.yyyyMMddKey {
            NSLog("SKItemStack error, trying to show item for date \(item.date) but stack date is \(self.date.yyyyMMddKey), ignoring.")
        }
        if self.date.yyyyMMddKey != item.date.yyyyMMddKey {
            NSLog("SKItemStack error, trying to show item for date \(item.date) but stack date is \(self.date.yyyyMMddKey), ignoring.")
        }
    }
}
