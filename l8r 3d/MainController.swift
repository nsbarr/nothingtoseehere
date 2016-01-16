//
//  Copyright (c) 2015 The Web Electric Corp. All rights reserved.
//

import SceneKit
import QuartzCore
import Foundation

import J58


class MainController : AppEventListener {
    let _listenerKey:String = String.createUUIDString()!
    var listenerKey:String { return _listenerKey }
    
    var topLevelDirectory: String!
    var scnView:N3xtSCNView
    var hudSKScene: N3xtHUDSKScene!
    var worldController: WorldController!
    
    
    init(view: N3xtSCNView, hudScene: N3xtHUDSKScene! = nil) {
        
        /* TODO re-enable settings
        if let storedTopLevelDir = AppSettings.sharedInstance[SettingsKeys.TopLevelDir]?.string {
            self.topLevelDirectory = storedTopLevelDir
        }
        else {
            if let homeDirectory = FileSystem.homeDirectory() {
                self.topLevelDirectory = homeDirectory.NSStr.stringByAppendingPathComponent("Documents")
                AppSettings.sharedInstance.setValue(self.topLevelDirectory, forKey: SettingsKeys.TopLevelDir)
            }
            else {
                fatalError("Call to obtain homeDirectory returned nil")
            }
        }
*/
        //TODO reset to using iCloud and switching between different versions/OS capabilities
        //default Directory config
        
        
        self.scnView = view
        
        
    }
    
    func initializeWorld(showHUD: Bool = false) -> WorldController {
        self.worldController = WorldController()
        
        //create standard scnView
        self.scnView.delegate = self.worldController
        self.scnView.play(self)
        self.hudSKScene = N3xtHUDSKScene(size: self.scnView.frame.size)
        self.scnView.overlaySKScene = self.hudSKScene
        
        if showHUD {
            //            self.hudSKScene = N3xtHUDSKScene(size: self.scnView.frame.size)
            //        NSLog("sz = \(self.scnView.frame.size)")
            //        //        NSThread.dispatchAsyncOnMainQueue(afterDelay: 5) { () -> Void in
            //        self.hudScene.backgroundColor = SKColor.redColor()
            //        self.scnView.overlaySKScene = self.hudScene
            
            //        self.hudScene.bottomRightLabel = "rightlabel:"
            //        self.hudScene.bottomRightText = "right textright textright text"
            //        self.hudScene.bottomLeftLabel = "leftlabel:"
            //        self.hudScene.bottomLeftText = "left textleft text"
        }
        
        worldController.connectWithView(scnView)
        
        
        let viewConfiguration:[String: AnyObject] = [
            "autoenablesDefaultLighting" : false,
            "antialiasingMode" : SCNAntialiasingMode.Multisampling4X.rawValue,
            "jitteringEnabled" : true
        ]
        
        let nodeGroupKeyToTypeMappings:[String: SCNNodeGroupParameters] = [
            "Start"     : SCNNodeGroupParameters(groupType: NodeGroupStart.self, daeAssetName: nil, daeAssetFileName: nil),
            "Logo"      : SCNNodeGroupParameters(groupType: NodeGroupLogo.self, daeAssetName: "logo_icon", daeAssetFileName: "location_logo"),
            "L8RBox": SCNNodeGroupParameters(groupType: NodeGroupL8RBox.self, daeAssetName: nil, daeAssetFileName: nil),
        ]
        let locationsSceneFilename = "locations"
        let worldSetupSceneFilename = "world"
        let initialLocationName = "start"
        worldController.loadWorld(nodeGroupKeyToTypeMappings, locationsSceneFilename: locationsSceneFilename, viewConfiguration:viewConfiguration)
        worldController.setupEnvironment(worldSetupSceneFilename, useSkybox: false)
        worldController.initializeWorldView(initialLocationName)
        //camera is setup after we have set the initial location (which will typically be a temporary, starting point, for an animation
        //that eventually 'arrives' at the first location, eg. a logo)
        worldController.setupStandardCamera()
        
        return worldController
    }
    
    func appEventGetRequested<T>(event:NXGetAttributeEvent<T>) -> AnyObject? {
        return nil
    }
    
    func appEventSetRequested<T>(key: AppEventKey, value: T) {
    }
    
    func appEventTriggered(event:AppEvent) {
    }
    
    func changeTopLevelDir(path: String) {
        
        if self.topLevelDirectory == path {
            return
        }
        
        if path.isEmpty {
            NSLog("Requested change of top level dir to an empty string - ignoring")
        }
        
    }
    
    
    func prepare() {
        
    }
    
    func startProcesses() {
        
    }
    
    func stopProcesses() {
        
    }
}