//
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation
import SpriteKit



extension CGSize {
    var center:CGPoint {
        return CGPoint(x: self.width/2, y: self.height/2)
    }
}

extension UIView {
    func addSwipeGestureRecognizer(recognizer:UISwipeGestureRecognizer, direction:UISwipeGestureRecognizerDirection) {
        recognizer.direction = direction
        self.addGestureRecognizer(recognizer)
        
    }
}
extension Int {
    var cgf:CGFloat {
        return CGFloat(self)
    }
}

extension Float {
    var cgf:CGFloat {
        return CGFloat(self)
    }
}

extension CGFloat {
    var f:Float {
        return Float(self)
    }
    
    var i:Int {
        return Int(self)
    }

    func scaleBy(scale:CGFloat) -> CGFloat {
        return self * scale
    }

}

public extension SKSpriteNode {
    public var width:CGFloat {
        set {
            self.size = CGSize(width: width, height: self.size.height)
        }
        get {
            return self.size.width
        }
    }
    
    public var height:CGFloat {
        set {
            self.size = CGSize(width: self.size.width, height: height)
        }
        get {
            return self.size.height
        }
    }

}

extension SKTexture {
    convenience init(layer:CALayer) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGBitmapContextCreate(nil, layer.frame.size.width.i, layer.frame.size.height.i, 8, 0, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)
        CGContextSetAllowsAntialiasing(context, true)
        layer.renderInContext(context!)
        let image = CGBitmapContextCreateImage(context)
        self.init(CGImage: image!)
        
    }
}


class SKButtonNode : SKSpriteNode {
    
    var action:((buttonNode:SKButtonNode) -> Void)!
    
    init(texture:SKTexture?, color:SKColor, size:CGSize, action:((buttonNode:SKButtonNode) -> Void)) {
        self.action = action
        super.init(texture: texture, color: color, size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var reactsToTap:Bool {
        return true
    }
    
    override func processTap(atPosition position:CGPoint, recognizer:UITapGestureRecognizer) -> Bool {
        if let action = self.action {
            action(buttonNode: self)
            return true
        }
        return false
    }
}

public extension SKNode {
    
    var reactsToTap:Bool {
        return false
    }
    func processTap(atPosition position:CGPoint, recognizer:UITapGestureRecognizer) -> Bool {
        return false
    }

        class func skLabelWithText(text:String, atPosition position:CGPoint, fontSize: CGFloat = 20, color:SKColor = SKColor.blackColor(), fontName:String = "San Francisco") -> SKLabelNode {
            let textNode = SKLabelNode(text: text)
            textNode.position = position
            textNode.fontSize = fontSize
            textNode.fontName = fontName
            textNode.fontColor = color
            
            
            return textNode
        }

    public func adjustPositionXBy(value:CGFloat) {
        self.position = CGPoint(x: self.position.x+value, y: self.position.y)
    }
    public func adjustPositionYBy(value:CGFloat) {
        self.position = CGPoint(x: self.position.x, y: self.position.y+value)
    }
    
    public var x:CGFloat {
        get {
            return self.position.x
        }
        set {
            self.position = CGPoint(x: newValue, y: self.position.y)
        }
    }
    public var y:CGFloat {
        get {
            return self.position.y
        }
        set {
            self.position = CGPoint(x: self.position.x, y: newValue)
        }
    }
}
