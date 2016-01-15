//
//  Copyright © 2016 poemsio. All rights reserved.
//

import UIKit

public let L8RCreatedNotification:String = "L8RCreatedNotification"
public let L8RCreatedNotification_ItemKey:String = "L8RCreatedNotification_ItemKey"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        switchScreenLock(true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "l8rCreatedCallback:", name: L8RCreatedNotification, object: nil)

        return true
    }
    
    deinit {

        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    
    func switchScreenLock(enabled:Bool) {
        //this call disables automatic screen locking when the app is running, useful for debugging
        //compiler removes this code when not in debug mode
        #if DEBUG
            UIApplication.sharedApplication().idleTimerDisabled = true
        #endif
    }
    
    func l8rCreatedCallback(notification:NSNotification) {
        //notifications are executed synchronously on the calling thread, push it to background on main
        NSThread.dispatchAsyncOnMainQueue() {
            //do stuff after a l8r is created. Some people report that after taking a photo it's possible to see this global
            //variable affected, so we reset it here
            self.switchScreenLock(true)
            
            //example of how to extract the l8ritem info for processing, etc
//            if let info = notification.userInfo, item = info[L8RCreatedNotification_ItemKey] as? L8RItem {
//                print("item created event received: \(item.createdDate)")
//            }
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        switchScreenLock(false)

    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        switchScreenLock(true)

        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

