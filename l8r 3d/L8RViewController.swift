//
//  Copyright (c) 2016 poemsio. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import J58

class L8RViewController: UIViewController {

    var scnView:N3xtSCNView! {
        return self.view as! N3xtSCNView
    }
    var appDelegate:L8RiOSAppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appDelegate = UIApplication.sharedApplication().delegate as! L8RiOSAppDelegate
        self.appDelegate.setupConnections(self)

    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
