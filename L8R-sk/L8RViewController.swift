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
    
    var photoCameraController:PhotoCameraController! {
        didSet {
            self.scene.photoCameraController = self.photoCameraController
        }
    }
    
    deinit {
        self.photoCameraController.teardownCamera()
        self.photoCameraController = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = self.view as! SKView
        scene = L8RScene(size: skView.bounds.size)

        //for testing
        items = L8RItemSet()
        items.setStandardPath()
        items.load()
        
//        let testSet = L8RItemSet.createTestItemSet()
//        for item in testSet.allItems {
//            items.addItem(item)
//        }
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        
//        skView.ignoresSiblingOrder = true
        
        
        skView.presentScene(scene)

        scene.loadItems(items)
    }
    
    override func viewDidAppear(animated: Bool) {
        scene.returnToToday()
        
        //        scene.testScrolling()
        
        NSThread.dispatchAsyncOnMainQueue() {
            self.photoCameraController = PhotoCameraController()
            self.photoCameraController.checkCameraAccess({ (accessGranted) -> Void in
                // If permission hasn't been granted, notify the user.
                if !accessGranted {
                    NSThread.dispatchAsyncOnMainQueue() {
                        
                            let message =  "L8R needs access to the camera, please check your privacy settings."
                            let alert = UIAlertController(title: "Could not use camera!", message: message, preferredStyle: .Alert)
                            alert.addAction(UIAlertAction(title: "OK.", style: .Default) { _ in })
                            
                            self.presentViewController(alert, animated: true) {
                            }

                    }
                }
                else {
                    self.photoCameraController.prepareCamera()
                }
            })
        }
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
