//
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation
import SpriteKit


class CreateL8RSKNode : SKSpriteNode {
    
    
    init(size:CGSize) {
        super.init(texture: nil, color: SKColor.greenColor(), size: size)
        self.name = "CreateL8RSKNode"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}