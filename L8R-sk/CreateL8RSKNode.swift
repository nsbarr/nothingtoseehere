//
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation
import SpriteKit



public class CreateL8RSKNode : SKSpriteNode {
    
    private var snapButtonNode:SKButtonNode!
    public var takePhotoAction:(() -> Void)!
    
    public init(size:CGSize) {
        super.init(texture: nil, color: SKColor.greenColor(), size: size)
        self.name = "CreateL8RSKNode"
        
        let snapTexture = SKTexture(imageNamed: "snapButtonImage")
        self.snapButtonNode = SKButtonNode(texture: snapTexture, color: SKColor.clearColor(), size: snapTexture.size()) { [weak self] (buttonNode:SKButtonNode) -> Void in
            
            self?.snapButtonTapped()
            
        }
        let x = self.width/2 - snapButtonNode.width/2 - 20
        let y = -self.height/2 + snapButtonNode.width/2 + 20
        
        self.snapButtonNode.position = CGPoint(x: x, y: y)
        self.addChild(self.snapButtonNode)
    }
    
    func snapButtonTapped() {
        if let action = self.takePhotoAction {
            NSThread.dispatchAsyncOnMainQueue() {
                action()
            }
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateCameraFrame(image:SKTexture?) {
        if let textureImage = image {
//            NSThread.dispatchAsyncOnMainQueue() {
            self.texture = textureImage//SKTexture(image: textureImage)
//            }
        }
        else {
            //TODO set to a default?
        }
        
    }
}