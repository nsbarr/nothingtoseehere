//
//  AppDelegate.swift
//  l8r 3d
//
//  Created by Diego Doval on 1/15/16.
//  Copyright © 2016 poemsio. All rights reserved.
//

import UIKit
import J58

//TODO this will need some tweaking to make it easier to switch between OSes
extension NXAppEventKey {
    public static let ShowAlert = NXAppEventKey("ShowAlert")
}

@UIApplicationMain
class L8RiOSAppDelegate: UIResponder, UIApplicationDelegate, AppEventListener {
    let _listenerKey:String = String.createUUIDString()!
    var listenerKey:String { return _listenerKey }

    var window: UIWindow?
    weak var worldController:NXWorldController!
    var mainController: MainController!
    
    var hudScene:N3xtHUDSKScene!
    var scnView:N3xtSCNView! {
        return self.l8rViewController?.scnView
    }
    weak var l8rViewController:L8RViewController!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        NXAppEvents.registerAction(self, forEvent: NXAppEventKey.ShowAlert)
        return true
    }
    
    func setupConnections(viewController: L8RViewController) {
        self.l8rViewController = viewController
        self.mainController = MainController(view: self.scnView)
        self.worldController = self.mainController.initializeWorld(false)
        self.scnView.worldController = self.worldController
        //        scnView.showsStatistics = true
        self.hudScene = self.mainController.hudSKScene
    }
    
    
    func appEventGetRequested<T>(event:NXGetAttributeEvent<T>) -> AnyObject? {
        return nil
    }
    
    func appEventSetRequested<T>(key: NXAppEventKey, value: T) {
    }
    
    
    func appEventTriggered(event: NXAppEvent) {
        
        if event.key == NXAppEventKey.ShowAlert {
            NSThread.dispatchAsyncOnMainQueue() {
                let message =  event.info["message"] as? String ?? "<no message>"
                let title =  event.info["title"] as? String ?? "<title>"
                let actionButton = event.info["actionButton"] as? String ?? "OK"
                let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: actionButton, style: .Default) { _ in })
                    self.l8rViewController?.presentViewController(alert, animated: true) {
                }
            }

        }
    }


    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

