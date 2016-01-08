//
//  Copyright (c) 2016 poemsio. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation
import Photos

class L8RViewController: UIViewController {

    var scene:L8RScene!
    var items:L8RItemSet!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = self.view as! SKView
        scene = L8RScene(size: skView.bounds.size)

        //for testing
        items = L8RItemSet()
        items.setStandardPath()
        items.load()
        
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        
//        skView.ignoresSiblingOrder = true
        
        
        skView.presentScene(scene)

        scene.loadItems(items)


    }
    
    override func viewDidAppear(animated: Bool) {
        scene.returnToToday()
        
        //        scene.testScrolling()
        
        

        scene.setupCamera()
    }

    
    
    
    override func shouldAutorotate() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .Portrait
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
