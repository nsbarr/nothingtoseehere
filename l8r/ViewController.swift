//
//  ViewController.swift
//  l8r
//
//  Created by nick barr on 11/23/15.
//  Copyright © 2015 poemsio. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import GameplayKit

class MenuButton: UIButton {
    override init(frame: CGRect)  {
        super.init(frame: frame)
        
        self.titleLabel!.font = UIFont(name: "ChalkboardSE-Regular", size: 20.0)
        self.titleLabel!.textAlignment = .Center
        self.contentVerticalAlignment = .Center
        self.titleLabel?.numberOfLines = 1
        self.setTitleColor(UIColor.blackColor(), forState: .Normal)
        self.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        self.layer.borderColor = UIColor.grayColor().CGColor
        self.layer.cornerRadius = 12
        self.layer.borderWidth = 0
        self.layer.shadowColor = UIColor.grayColor().CGColor
        self.layer.shadowOffset = CGSizeMake(0, 1)
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 1
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate, UIAlertViewDelegate {
    
    
    //TODO:
    
    
    
    // camera show up nicer
    //"inspiration"?💡
    //don't allow blank album titles
    //finalize alert design
    //ability to cancel from new tag
    //subtle button change on highlighted state (bounce effect?)
    // third bg
    //OneStroke -- record on touchDown, stop on TouchUp
    //move text?
    //onboarding
    
    
    //  MARK: - Variables
    
    
    
    //l8r setup
    var l8rView = UIView()
    
    //camera setup
    var previewLayer : AVCaptureVideoPreviewLayer?
    var backCameraDevice:AVCaptureDevice?
    var frontCameraDevice:AVCaptureDevice?
    var stillCameraOutput:AVCaptureStillImageOutput!
    let session = AVCaptureSession()
    var currentInput: AVCaptureDeviceInput?
    var currentDeviceIsBack = true
    var sessionQueue = dispatch_queue_create("com.example.camera.capture_session", DISPATCH_QUEUE_SERIAL)
    var tempPreviewLayerView = UIImageView()
    
    var previewLayerImage = UIImage()
    
    //hud setup
    var hudView = UIView()
    var snapButton:UIButton!
    var snoozeLabel:UIButton!
    var bgButton: UIButton!
    var labelContainerView = UIView()
    let diameter:CGFloat = 40
    var refreshButton: UIButton!
    var g8rView = UIView()

    
    //l8r setup
    var albumLabel:MenuButton!
    var l8rTagArray = NSUserDefaults.standardUserDefaults().objectForKey("SavedArray") as? [String] ?? [String]()
    var l8rImage = UIImage()

    
    //draw setup
    var faceView = UIImageView()
    var tempImageView = UIImageView()
    var bottomView = UIView()
    var opacity:CGFloat = 0.8
    var swiped = false
    var canDraw = true
    var lastPoint = CGPoint.zero
    
//    let yellow = UIColor(red: 254/255, green: 235/255, blue: 157/255, alpha: 1)
//    let pink = UIColor(red: 229/255, green: 121/255, blue: 146/255, alpha: 1)
//    var green = UIColor(red: 136/255, green: 219/255, blue: 201/255, alpha: 1)
    
    let yellow = UIColor(red: 252/255, green: 250/255, blue: 0/255, alpha: 1)
    let pink = UIColor(red: 255/255, green: 0/255, blue: 173/255, alpha: 1)
    let green = UIColor(red: 31/255, green: 255/255, blue: 35/255, alpha: 1)
    let blue = UIColor(red: 0/255, green: 209/255, blue: 255/255, alpha: 1)
    
    
    var brushWidth:CGFloat = 10.0
    var currentColor = UIColor()
    var colorPaletteButton = UIButton()
    
    var bgView = UIView()
    
    //text setup
    var textView: UITextView!
    
    
    //album setup
    var albumFound = false
    var albumName = "l8rTest"
    var collection: PHAssetCollection = PHAssetCollection()
    var photosAsset: PHFetchResult!
    var placeholder: PHObjectPlaceholder!
    let placeholderTextArray = ["🍣 sushi","💡inspiration","🍶 sake labels", "🎨 art", "💸 wanna buy", "📖 deep thoughtz"]
    
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        hudView = UIView(frame: self.view.frame)
        l8rView = UIView(frame: self.view.frame)
        
        self.view.addSubview(l8rView)
        self.view.addSubview(hudView)

        
        self.setUpCamera()
        
    
        l8rView.addSubview(faceView)
        l8rView.addSubview(tempImageView)
        
        self.updateDrawViews()
        
        self.addBottomButtons()
        self.addTopButtons()




        

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpCamera(){
        let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableCameraDevices as! [AVCaptureDevice] {
            if device.position == .Back {
                backCameraDevice = device
            }
            else if device.position == .Front {
                frontCameraDevice = device
            }
        }
        
        var error:NSError?
        let possibleCameraInput: AnyObject?
        do {
            possibleCameraInput = try AVCaptureDeviceInput(device: backCameraDevice)
        } catch let error1 as NSError {
            error = error1
            possibleCameraInput = nil
        }
        if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
            if self.session.canAddInput(backCameraInput) {
                currentInput = backCameraInput
                self.session.addInput(currentInput)
            }
        }
        
        stillCameraOutput = AVCaptureStillImageOutput()
        
        if self.session.canAddOutput(self.stillCameraOutput) {
            self.session.addOutput(self.stillCameraOutput)
        }
        
        //this auto-handles focus, WB, exposure, etc.
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        l8rView.layer.addSublayer(previewLayer!)
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        dispatch_async(sessionQueue) { () -> Void in
            self.session.startRunning()
        }
        previewLayer?.connection?.enabled = true
        
        
    }
    
    func addBottomButtons(){
        
        let yPos:CGFloat = 20
        
        
        snapButton = UIButton(frame: CGRect(x: self.view.frame.width-(diameter+40+10), y: self.view.frame.height-(diameter+40), width: diameter+30, height: diameter+30))
        let buttonImage = UIImage(named: "snapButtonImage")
        snapButton.setImage(buttonImage, forState: .Normal)
       // snapButton.center.x = self.view.center.x
        
      //  let buttonEnabledImage = UIImage(named: "snapButtonImageClosed")
      //  snapButton.setImage(buttonEnabledImage, forState: UIControlState.Selected)
        
        
        snapButton.hidden = false
        snapButton.addTarget(self, action: Selector("snapButtonTapped:"), forControlEvents: .TouchUpInside)

        
        hudView.addSubview(snapButton)

            
            //TODO: - don't hardcode this
            

        

        
        refreshButton = UIButton(frame: CGRect(x: 10, y: yPos, width: diameter, height: diameter))
        refreshButton.setTitle("🍃", forState: .Normal)
        refreshButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        refreshButton.addTarget(self, action: Selector("refreshView:"), forControlEvents: .TouchUpInside)
        refreshButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        refreshButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        refreshButton.titleLabel!.layer.shadowOpacity = 1
        refreshButton.titleLabel!.layer.shadowRadius = 1
        refreshButton.hidden = true
        
        hudView.addSubview(refreshButton)
        
//        flash doesn't work
//        let flashButton = UIButton(frame: CGRect(x: xPos, y: self.view.frame.height-60, width: diameter, height: diameter))
//        flashButton.setImage(UIImage(named: "flashOff"), forState: .Normal)
//        flashButton.setImage(UIImage(named: "flashOn"), forState: .Selected)
//        flashButton.addTarget(self, action: Selector("toggleFlash:"), forControlEvents: .TouchUpInside)
//        hudView.addSubview(flashButton)
//        
        
        let g8rButton = UIButton(frame: CGRect(x: self.view.frame.width-(diameter+10), y: yPos, width: diameter, height: diameter))
        g8rButton.setTitle("🐊", forState: .Normal)
        g8rButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        g8rButton.addTarget(self, action: Selector("showG8rView:"), forControlEvents: .TouchUpInside)
        g8rButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        g8rButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        g8rButton.titleLabel!.layer.shadowOpacity = 1
        g8rButton.titleLabel!.layer.shadowRadius = 1
        g8rButton.center.x = hudView.center.x
        hudView.addSubview(g8rButton)

        
        
        let hideHudButton = UIButton(frame: CGRect(x: self.view.frame.width-(diameter+10), y: yPos, width: diameter, height: diameter))
        hideHudButton.setTitle("🙈", forState: .Normal)
        hideHudButton.setTitle("🐵", forState: .Selected)
        hideHudButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        hideHudButton.addTarget(self, action: Selector("toggleHud:"), forControlEvents: .TouchUpInside)
        hideHudButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        hideHudButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        hideHudButton.titleLabel!.layer.shadowOpacity = 1
        hideHudButton.titleLabel!.layer.shadowRadius = 1
        self.view.addSubview(hideHudButton)
        

    }
    
    func addTopButtons(){
        
        let yPos = snapButton.frame.midY-diameter/2
        
        bgButton = UIButton(frame: CGRect(x: 20, y: yPos, width: diameter, height: diameter))
        bgButton.setTitle("📓", forState: .Normal)
        bgButton.setTitle("📷", forState: .Selected)
        bgButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        bgButton.addTarget(self, action: Selector("toggleBg:"), forControlEvents: .TouchUpInside)
        bgButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        bgButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        bgButton.titleLabel!.layer.shadowOpacity = 1
        bgButton.titleLabel!.layer.shadowRadius = 1
        hudView.addSubview(bgButton)
        
        let flipButton = UIButton(frame: CGRect(x: 80, y: yPos, width: diameter, height: diameter))
        flipButton.setTitle("😎", forState: .Normal)
        flipButton.setTitle("🌎", forState: .Selected)
        flipButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        flipButton.addTarget(self, action: Selector("toggleCamera:"), forControlEvents: .TouchUpInside)
        flipButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        flipButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        flipButton.titleLabel!.layer.shadowOpacity = 1
        flipButton.titleLabel!.layer.shadowRadius = 1
        hudView.addSubview(flipButton)
        
        
        let colorPaletteButton = UIButton(frame: CGRect(x: 140, y: yPos, width:diameter, height:diameter))
        currentColor = pink
        
        colorPaletteButton.setImage(UIImage(named: "colorPalettePink"), forState: .Normal)
        colorPaletteButton.setImage(UIImage(named:"colorPaletteYellow"), forState: .Selected)
        
        colorPaletteButton.addTarget(self, action: Selector("toggleColorPalettes:"), forControlEvents: .TouchUpInside)
        hudView.addSubview(colorPaletteButton)
        
        let textButton = UIButton(frame: CGRect(x: 200, y: yPos, width: diameter, height: diameter))
        
        textButton.setTitle("✏️", forState: .Normal)
        textButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        textButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        textButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        textButton.titleLabel!.layer.shadowOpacity = 1
        textButton.titleLabel!.layer.shadowRadius = 1
        
        textButton.addTarget(self, action: Selector("toggleKeyboard:"), forControlEvents: .TouchUpInside)
        hudView.addSubview(textButton)
        
    }
    
    func toggleFlash(sender: UIButton){
        sender.selected = !sender.selected
        //TODO: Actually toggle Flash
    }
    
    func toggleHud(sender: UIButton){
        sender.selected = !sender.selected
        hudView.hidden = !hudView.hidden
        
    }
    
    func toggleBg(sender: UIButton){
        sender.selected = !sender.selected

        if sender.selected{
        
            bgView = UIView(frame: self.view.frame)
            let bgImage = UIImage(named: "bgImagePattern")
            bgView.backgroundColor = UIColor(patternImage: bgImage!)
            l8rView.insertSubview(bgView, belowSubview: faceView)
        }
        
        else {
            bgView.removeFromSuperview()
        }

    }
    
    func refreshView(sender: UIButton){
        self.faceView.image = nil
        
        if textView != nil{
            textView.text = ""
        }

        
        refreshButton.hidden = true
        
    }
    
    func toggleColorPalettes(sender: UIButton){
        if currentColor == pink{
            print("pink -> yellow")
            currentColor = yellow
            sender.setImage(UIImage(named:"colorPaletteYellow"), forState: .Normal)

        }
        else if currentColor == yellow{
            print("yellow -> green")

            currentColor = green
            sender.setImage(UIImage(named:"colorPaletteGreen"), forState: .Normal)

        }
        else {
            print("green -> pink")
            currentColor = pink
            sender.setImage(UIImage(named:"colorPalettePink"), forState: .Normal)

       //     colorPaletteButton.setImage(UIImage(named:"colorPalettePink"), forState: .Normal)

        }
        
    }
    
    func flashConfirm(){
        
        let flashConfirm = UIImageView(frame: CGRect(x:0, y: 0, width: self.view.frame.width-100, height: self.view.frame.width-100))
        flashConfirm.center = self.view.center
        flashConfirm.image = UIImage(named: "flashConfirmImage")
        flashConfirm.contentMode = UIViewContentMode.ScaleAspectFit
        flashConfirm.alpha = 0
        self.view.addSubview(flashConfirm)
        
        self.resetL8r()
        
        UIView.animateKeyframesWithDuration(0.2, delay: 0.2, options: [], animations: { () -> Void in
            flashConfirm.alpha = 1
            //  flashConfirm.frame = CGRectMake(self.view.frame.midX, self.view.frame.midY, 0, 0)
            }, completion: {finished in
                UIView.animateKeyframesWithDuration(0.2, delay: 0.2, options: [], animations: { () -> Void in
                    flashConfirm.alpha = 0
                    }, completion: {finished in
                        flashConfirm.removeFromSuperview()
                })
        })
    }

    
    func snapButtonTapped(sender: UIButton){
        
        
        if !sender.selected{
            sender.selected = true
            sender.tag = 2
            self.turnPreviewLayerIntoImage()
            self.previewLayer?.connection.enabled = false
            self.appearL8rLabels()
            sender.setImage(UIImage(named:"snapButtonImageOpen"), forState: .Selected)
            
        }
        else if sender.tag == 2{ //close tags
            sender.tag = 3
            for view in hudView.subviews {
                if view.isKindOfClass(MenuButton) {
                    view.removeFromSuperview()
                }
                sender.setImage(UIImage(named:"snapButtonImageClosed"), forState: .Selected)

            }
        }
        else if sender.tag == 3{
            self.appearL8rLabels()
            sender.tag = 2
            sender.setImage(UIImage(named:"snapButtonImageOpen"), forState: .Selected)



        }

    }
    
    func showCreateAlbumAlert(){
        
//        let alert = UIAlertView(title: "Give the album a name", message: "", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Ok")
//        alert.alertViewStyle = UIAlertViewStyle.PlainTextInput
//        alert.show()
        
        
        var albumTextField: UITextField?
        let alert = UIAlertController(title: "Cool Alert", message: "Name your Tag", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in
            if #available(iOS 9.0, *) {
                let shuffled = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(self.placeholderTextArray)
                textField.placeholder = shuffled[0] as? String
            } else {
                //TODO: random that doesn't require ios9
                textField.placeholder = "New chill tag"
            }
            albumTextField = textField
        }
        let defaultAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            self.albumName = albumTextField!.text!
            
            self.stampL8rForSharing()
            self.savePhotoToAlbum(self.l8rImage, albumName: self.albumName)

        }
        alert.addAction(defaultAction)
        self.presentViewController(alert, animated: true, completion: nil)

    }
    
    func dismissG8rView(sender: UIButton){
        g8rView.removeFromSuperview()
        canDraw = true
    }
    
    
    func fetchListOfL8rAlbums(){
        var assetCollections = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumRegular, options: nil)
        
        for var i = 0 ; i < assetCollections.count ; i++
        {
            let assetCollection = assetCollections[i] as? PHAssetCollection
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.Image.rawValue)
            
            let assetsInCollection  = PHAsset.fetchAssetsInAssetCollection(assetCollection!, options: fetchOptions)
            
            if assetCollection?.localizedTitle!.rangeOfString("l8r") != nil{
                
                if let localizedTitle = assetCollection?.localizedTitle
                {
                    let l8rLessTitle = localizedTitle.stringByReplacingOccurrencesOfString("l8r", withString: "")
                    print(l8rLessTitle)
                    
                }
            }
        }

    }
    
    
    
    func openTwitterProfile(sender: UIButton){
        UIApplication.sharedApplication().openURL(NSURL(string:"http://twitter.com/l8rapp")!)
    }
    
    func showG8rView(sender: UIButton){
        canDraw = false
        g8rView = UIView(frame: self.view.frame)
        g8rView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        self.view.addSubview(g8rView)
        
        let g8rImageView = UIImageView(frame: g8rView.frame)
        g8rImageView.image = UIImage(named:"hastyg8r")
        g8rView.addSubview(g8rImageView)
        

        
        
        
        let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let appBundle = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as! String
        
        let versionLabel = UILabel(frame: CGRectMake(0,20,200,40))
        versionLabel.text = "Version: \(version)"
        versionLabel.font = UIFont(name: "ChalkboardSE-Regular", size: 20.0)
        versionLabel.textColor = UIColor.whiteColor()
        
        versionLabel.textAlignment = .Center
        
        let appBundleLabel = UILabel(frame: CGRectMake(0,60,200,40))
        appBundleLabel.text = "Bundle: \(appBundle)"
        appBundleLabel.font = UIFont(name: "ChalkboardSE-Regular", size: 20.0)
        appBundleLabel.textColor = UIColor.whiteColor()
        appBundleLabel.textAlignment = .Center

        
        let explainText = UILabel(frame: CGRectMake(0,140,g8rView.frame.width-40,40))
        explainText.text = "Confused? Your tags sync with Albums in the Photos App. \n" + "\n" +
                            "To see them, open Photos. \n" + "\n" +
                           "Still confused? Or just want to say what's up? Holler at me on Twitter"
        explainText.font = UIFont(name: "ChalkboardSE-Regular", size: 20.0)
        explainText.textColor = UIColor.whiteColor()
        explainText.numberOfLines = 0
        explainText.sizeToFit()
        explainText.textAlignment = .Center
        
        
        versionLabel.center.x = g8rView.center.x
        appBundleLabel.center.x = g8rView.center.x
        explainText.center.x = g8rView.center.x
        g8rView.addSubview(explainText)
        g8rView.addSubview(versionLabel)
        g8rView.addSubview(appBundleLabel)
        
        
        

    
        
        
        let twitterButton = MenuButton(frame: CGRectMake(0,0,100,100))
        twitterButton.setTitle("@l8rg8r", forState: .Normal)
        twitterButton.contentVerticalAlignment = .Center
        twitterButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
        twitterButton.sizeToFit()
        twitterButton.backgroundColor = blue
        twitterButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        twitterButton.addTarget(self, action: Selector("openTwitterProfile:"), forControlEvents: .TouchUpInside)
        var newFrame = twitterButton.frame
        newFrame.size.width += 20 //l + r padding
        twitterButton.frame = newFrame
        twitterButton.center.x = g8rView.center.x
        g8rView.addSubview(twitterButton)
        twitterButton.frame.origin.y = explainText.frame.maxY + 30

        
        
        let dismissButton = MenuButton(frame: CGRectMake(0,0,100,100))
        dismissButton.setTitle("back to l8r", forState: .Normal)
        dismissButton.contentVerticalAlignment = .Center
        dismissButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
        dismissButton.sizeToFit()
        dismissButton.backgroundColor = pink
        dismissButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        dismissButton.addTarget(self, action: Selector("dismissG8rView:"), forControlEvents: .TouchUpInside)
        newFrame = dismissButton.frame
        newFrame.size.width += 20 //l + r padding
        dismissButton.frame = newFrame
        dismissButton.center.x = g8rView.center.x
        g8rView.addSubview(dismissButton)
        dismissButton.frame.origin.y = twitterButton.frame.maxY + 30
        


        
        
        
        
    //        all this is for the alert Modal
    //        let modalView = UIView(frame: self.view.frame)
    //        modalView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
    //        self.view.addSubview(modalView)
    //        
    //        let g8rImageView = UIImageView(frame: self.view.frame)
    //        g8rImageView.image = UIImage(named: "g8rView")
    //        modalView.addSubview(g8rImageView)
    //        
    //        let textField = UITextField(frame: CGRectMake(0,0,100,30))
    //        textField.center = g8rImageView.center
    //        textField.backgroundColor = UIColor.whiteColor()
    //        textField.borderStyle = UITextBorderStyle.Line
    //        textField.center = g8rImageView.center
    //            
    //        g8rImageView.addSubview(textField)
    //        g8rImageView.contentMode = UIViewContentMode.ScaleAspectFit
            
    //        let storyboard = UIStoryboard(name: "Main", bundle: nil)
    //        let vc = storyboard.instantiateViewControllerWithIdentifier("g8rViewController") as UIViewController
    //        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func appearL8rLabels(){
        
        let yBuff:CGFloat = 20
   //     let initialBuff:CGFloat = 40
        var numberOfLabels: Int
        let labelHeight:CGFloat = 40
        
        let newTagLabel = MenuButton(frame: CGRectMake(0,0,100,labelHeight))
        newTagLabel.center.y = snapButton.frame.minY - (labelHeight+yBuff)
        newTagLabel.setTitle("new tag", forState: .Normal)
    
        newTagLabel.contentVerticalAlignment = .Center
        newTagLabel.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
        newTagLabel.sizeToFit()
        newTagLabel.backgroundColor = green
        newTagLabel.setTitleColor(UIColor.whiteColor(), forState: .Normal)

        newTagLabel.addTarget(self, action: Selector("l8rLabelPressed:"), forControlEvents: .TouchUpInside)
        
        var newFrame = newTagLabel.frame
        newFrame.size.width += 20 //l + r padding
        newTagLabel.frame = newFrame
        newTagLabel.frame.origin.x = self.view.frame.width-(newTagLabel.frame.width+20)


        hudView.addSubview(newTagLabel)
        
        let shareTagLabel = MenuButton(frame: CGRectMake(0,0,100,labelHeight))
        shareTagLabel.center.y = snapButton.frame.minY - (labelHeight+yBuff)*2
        shareTagLabel.setTitle("share", forState: .Normal)
        
        shareTagLabel.contentVerticalAlignment = .Center
        shareTagLabel.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
        shareTagLabel.sizeToFit()
        shareTagLabel.backgroundColor = pink
        shareTagLabel.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        
        shareTagLabel.addTarget(self, action: Selector("l8rLabelPressed:"), forControlEvents: .TouchUpInside)
        
        newFrame = shareTagLabel.frame
        newFrame.size.width += 20 //l + r padding
        shareTagLabel.frame = newFrame
        shareTagLabel.frame.origin.x = self.view.frame.width-(shareTagLabel.frame.width+20)
        
        
        hudView.addSubview(shareTagLabel)
        
        
        
        if l8rTagArray.count > 0{
        
            if l8rTagArray.count > 6{
                numberOfLabels = 6
            }
            else {
                numberOfLabels = l8rTagArray.count
            }
            
       //     let startingHeight = snapButton.frame.minY - initialBuff - CGFloat(numberOfLabels)*(labelHeight+yBuff)

            for index in 1...numberOfLabels{
                albumLabel = MenuButton(frame: CGRectMake(0,0,100,labelHeight))
                albumLabel.center.y = snapButton.frame.minY - ((labelHeight+yBuff)*CGFloat(index+2))
                albumLabel.setTitle(l8rTagArray[index-1], forState: .Normal)
                albumLabel.contentVerticalAlignment = .Center
                albumLabel.sizeToFit()
                var newFrame = albumLabel.frame
                newFrame.size.width += 20 //l + r padding
                albumLabel.frame = newFrame



                albumLabel.frame.origin.x = self.snapButton.frame.maxX-(albumLabel.frame.width)
                albumLabel.addTarget(self, action: Selector("l8rLabelPressed:"), forControlEvents: .TouchUpInside)
                hudView.addSubview(albumLabel)
                
            }
        }
        else {
            print("can't show labels, array count is \(l8rTagArray.count)")
        }

        

        
        
//        let yBuffer:CGFloat = 60
//        labelContainerView = UIView(frame: CGRect(x: 0, y: snapButton.frame.minY-yBuffer, width: 200, height: 50))
//        labelContainerView.backgroundColor = UIColor.clearColor()
//        labelContainerView.userInteractionEnabled = true
//        hudView.addSubview(labelContainerView)
//        labelContainerView.center.x = self.view.center.x
        
        
//        
//        snoozeLabel = UIButton(frame: CGRectMake(0,0,50,50))
//        snoozeLabel.setBackgroundImage(UIImage(named: "snoozeLabel"), forState: .Normal)
//        snoozeLabel.alpha = 1.0
//        snoozeLabel.addTarget(self, action: Selector("l8rLabelPressed:"), forControlEvents: .TouchUpInside)
//        snoozeLabel.userInteractionEnabled = true
//        snoozeLabel.center.x = 200/2
//        labelContainerView.addSubview(snoozeLabel)
//        
//        let shareLabel = UIButton(frame: CGRectMake(60,0,50,50))
//        shareLabel.setBackgroundImage(UIImage(named: "shareLabel"), forState: .Normal)
//        shareLabel.alpha = 1.0
//        shareLabel.addTarget(self, action: Selector("l8rLabelPressed:"), forControlEvents: .TouchUpInside)
//        shareLabel.userInteractionEnabled = true
//        shareLabel.center.x = snoozeLabel.center.x-75
//
//        labelContainerView.addSubview(shareLabel)
//        
//        let albumLabel = UIButton(frame: CGRectMake(110,0,50,50))
//        albumLabel.setBackgroundImage(UIImage(named: "albumLabel"), forState: .Normal)
//        albumLabel.alpha = 1.0
//        albumLabel.addTarget(self, action: Selector("l8rLabelPressed:"), forControlEvents: .TouchUpInside)
//        albumLabel.userInteractionEnabled = true
//        albumLabel.center.x = snoozeLabel.center.x+75
//        labelContainerView.addSubview(albumLabel)
//        print(labelContainerView.frame)
//        labelContainerView.sizeThatFits(CGSize(width: albumLabel.frame.width*3, height: albumLabel.frame.height))
//        print(labelContainerView.frame)
    }
    
    
    func addTextView(){
        if textView == nil{
            textView = UITextView(frame: CGRectMake(10,10,self.view.frame.width, self.view.frame.height-70))
            textView.backgroundColor = UIColor.clearColor()
            textView.keyboardAppearance = UIKeyboardAppearance.Dark

            textView.returnKeyType = UIReturnKeyType.Done
            textView.userInteractionEnabled = false
            textView.delegate = self
            
            
            let font = UIFont(name: "ChalkboardSE-Regular", size: 38.0)!
            let textStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            textStyle.alignment = NSTextAlignment.Left
            let textColor = UIColor.whiteColor()
            
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.blackColor()
            shadow.shadowOffset = CGSizeMake(2.0,2.0)
            
            let attr = [
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: textColor,
                NSParagraphStyleAttributeName: textStyle,
                NSShadowAttributeName: shadow
            ]
            
            let placeholderText = NSAttributedString(string: " ", attributes: attr)
            textView.attributedText = placeholderText
            textView.text = ""
            textView.textContainerInset = UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20)
            //    textView.layer.borderColor = UIColor.redColor().CGColor
            //    textView.layer.borderWidth = 2.0
            textView.clipsToBounds = true
            
            l8rView.insertSubview(textView, aboveSubview: tempImageView)
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            refreshButton.hidden = false
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    

    
    func toggleKeyboard(sender: UIButton){
        self.addTextView()
        if textView.isFirstResponder() {
            
            //you could change the style here
            textView.resignFirstResponder()
            self.updateDrawViews()

        }
        else {
            textView.becomeFirstResponder()
            self.updateDrawViews()

        }
    }

    func l8rLabelPressed(sender: UIButton){
        self.stampL8rForSharing()
        //TODO: use tags here not text matching
        if sender.titleLabel?.text == "share"{
            self.openShareSheetWithImage(l8rImage)
        }
        else if sender.titleLabel?.text == "new tag"{
            
            self.showCreateAlbumAlert()
            // self.showG8rView()
        }
            
        else{
            albumName = (sender.titleLabel?.text)!
            self.savePhotoToAlbum(l8rImage, albumName: albumName)
            snapButton.selected = false

        }

        
    }
    
    func resetL8r(){
        self.previewLayer?.connection.enabled = true
        self.faceView.image = nil
        tempPreviewLayerView.image = nil
        previewLayerImage = UIImage()
        self.tempPreviewLayerView.removeFromSuperview()
        if textView != nil{
            textView.text = ""
        }

        snapButton.selected = false
        
        for view in hudView.subviews {
            if view.isKindOfClass(MenuButton) {
                view.removeFromSuperview()
            }
        }
        refreshButton.hidden = true

        

    }
    
    func updateDrawViews(){
        faceView.frame = CGRectMake(0,0,self.view.frame.width,self.view.frame.height)
        tempImageView.frame = CGRectMake(0,0,self.view.frame.width,self.view.frame.height)

        faceView.backgroundColor = UIColor.clearColor()
        
    }
    
    
    func turnPreviewLayerIntoImage(){
        dispatch_async(sessionQueue) { () -> Void in
            
            let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
            self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) {
                (imageDataSampleBuffer, error) -> Void in
                
                if error == nil {
                    print("should be disabling connection...")
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
               //     let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
                    
                    self.previewLayerImage = UIImage(data: imageData, scale: 1.0)!
                    
                    if !self.currentDeviceIsBack {
                        self.previewLayerImage = UIImage(CGImage: self.previewLayerImage.CGImage!, scale:self.previewLayerImage.scale, orientation: UIImageOrientation.LeftMirrored)
                        
                        //todo, some sizing?
        
                    }
                    
                    self.tempPreviewLayerView = UIImageView(frame: self.view.bounds)
                    self.tempPreviewLayerView.contentMode = UIViewContentMode.ScaleAspectFill
                    self.tempPreviewLayerView.image = self.previewLayerImage
                    
                    if self.bgView.superview != nil {
                        //don't add an imagelayer because we're looking at the bg
                    }
                    else {
                        self.l8rView.insertSubview(self.tempPreviewLayerView, belowSubview: self.faceView)
                    }
                   // self.openShareSheetWithImage(previewLayerImage!)
                    
                 //   let metadata2:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))!
                
                }
                    
                else {
                    NSLog("error while capturing still image: \(error)")
                }
            }
        }
    }
    
    func stampL8rForSharing(){
        
        UIGraphicsBeginImageContextWithOptions(l8rView.bounds.size, false, UIScreen.mainScreen().scale)
        l8rView.drawViewHierarchyInRect(l8rView.bounds, afterScreenUpdates: true)
        l8rImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsGetImageFromCurrentImageContext()
      //  self.openShareSheetWithImage(image)
    }
    
    func openShareSheetWithImage(image: UIImage){
        var sharingItems = [AnyObject]()
        
        let text = "Check out this L8R and create your own!"
        sharingItems.append(text)
        
        sharingItems.append(image)
        
        let url = NSURL(string: "http://lthenumbereightr.com")
        sharingItems.append(url!)
        
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
        
        activityViewController.completionWithItemsHandler = { activity, success, items, error in
            
            if success {
                print("success")
                self.flashConfirm()
            }
            else {
                print("cancel")
            }
            
        }
        
        
    }
    
    func drawLineFrom(fromPoint:CGPoint, toPoint:CGPoint){
        UIGraphicsBeginImageContext(self.view.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        tempImageView.image?.drawInRect(CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height))
        
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, 5)
        CGContextSetShouldAntialias(context, true)
       
        let colors = CGColorGetComponents(currentColor.CGColor)
        CGContextSetRGBStrokeColor(context, colors[0], colors[1], colors[2], 1)
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        
        CGContextStrokePath(context)
        
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImageView.alpha = opacity
        //CGContextSetShadowWithColor(context, CGSizeMake(0,1), 1, UIColor.blackColor().CGColor)
        UIGraphicsEndImageContext()
    }
    
    func toggleCamera(sender: UIButton) {
        
        self.previewLayer?.connection.enabled = true
        tempPreviewLayerView.image = nil
        previewLayerImage = UIImage()
        self.tempPreviewLayerView.removeFromSuperview()

        for view in hudView.subviews {
            if view.isKindOfClass(MenuButton) {
                view.removeFromSuperview()
            }
        }
        
        if bgView.superview != nil {
            bgView.removeFromSuperview()
            bgButton.selected = false
            
        }
        
        snapButton.selected = false

        
        if currentDeviceIsBack {
            var error:NSError?
            let possibleCameraInput: AnyObject?
            do {
                possibleCameraInput = try AVCaptureDeviceInput(device: frontCameraDevice)
            } catch let error1 as NSError {
                error = error1
                possibleCameraInput = nil
            }
            if let frontCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
                self.session.beginConfiguration()
                self.session.removeInput(currentInput)
                currentInput = frontCameraInput
                self.session.addInput(currentInput)
                self.session.commitConfiguration()
                currentDeviceIsBack = false
                sender.selected = !sender.selected
            }
            else {
                print("front camera not possible i guess?")
            }
        }
        else {
            var error:NSError?
            let possibleCameraInput: AnyObject?
            do {
                possibleCameraInput = try AVCaptureDeviceInput(device: backCameraDevice)
            } catch let error1 as NSError {
                error = error1
                possibleCameraInput = nil
            }
            if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
                self.session.beginConfiguration()
                self.session.removeInput(currentInput)
                currentInput = backCameraInput
                self.session.addInput(currentInput)
                self.session.commitConfiguration()
                currentDeviceIsBack = true
                sender.selected = !sender.selected
            }
            else {
                print("back camera not possible i guess?")
            }
            
        }
        
    }
    
    func savePhotoToAlbum(image: UIImage, albumName: String) {
        
        //Check if the folder exists, if not, create it
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let fetchResult:PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        if let first_Obj:AnyObject = fetchResult.firstObject{
            //found the album
            print("album exists")
            self.albumFound = true
            collection = first_Obj as! PHAssetCollection
            print(self.collection)
            print(self.collection.endDate)
            if self.l8rTagArray.contains(albumName){
                print("\(albumName) is in array")
                self.l8rTagArray.removeAtIndex(self.l8rTagArray.indexOf(albumName)!)
            }
            
            self.l8rTagArray.insert(albumName, atIndex: 0)
            NSUserDefaults.standardUserDefaults().setObject(self.l8rTagArray, forKey: "SavedArray")
        }
        else{

            //create the folder
            print("\nFolder does not exist\nCreating now...", albumName)
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let createAlbum = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(albumName)
                self.placeholder = createAlbum.placeholderForCreatedAssetCollection
                },
                completionHandler: {(success:Bool, error:NSError?)in
                    if(success){
                        print("Successfully created folder")
                        self.albumFound = true
                        let collectionFetchResult = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([self.placeholder.localIdentifier], options: nil)
                    //    let collection = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([albumPlaceholder.localIdentifier], options: nil)
                        self.collection = collectionFetchResult.firstObject as! PHAssetCollection

                    }else{
                        print("Error creating folder")
                        self.albumFound = false
                    }
                    if self.l8rTagArray.contains(albumName){
                        print("/(albumName) is in array")
                        self.l8rTagArray.removeAtIndex(self.l8rTagArray.indexOf(albumName)!)
                    }
                    self.l8rTagArray.insert(albumName, atIndex: 0)
                    NSUserDefaults.standardUserDefaults().setObject(self.l8rTagArray, forKey: "SavedArray")
                    
                    
            })
        }
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
            self.placeholder = assetRequest.placeholderForCreatedAsset
            self.photosAsset = PHAsset.fetchAssetsInAssetCollection(self.collection, options: nil)
            let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.collection, assets: self.photosAsset)
            albumChangeRequest?.addAssets([self.placeholder])
            }, completionHandler: { success, error in
                
                if (success){
                    print("added image to album")
                    //some save bullshit maybe later
                    //        NSString *UUID = [placeholder.localIdentifier substringToIndex:36];
                    //self.photo.assetURL = [NSString stringWithFormat:@"assets-library://asset/asset.PNG?id=%@&ext=JPG", UUID];
                    //[self savePhoto];

                }
                else {
                    print(error)
                }


                
                
        })
        self.flashConfirm()

    }
    

    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        swiped = false
        if let touch = touches.first{
            lastPoint = touch.locationInView(self.view)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.locationInView(self.view)
            if canDraw{
                drawLineFrom(lastPoint, toPoint: currentPoint)
            }
            lastPoint = currentPoint
        }
    }
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !swiped && canDraw {
            // uncomment if you like dots
            drawLineFrom(lastPoint, toPoint: lastPoint)
        }
        
        UIGraphicsBeginImageContext(faceView.frame.size)
        
        faceView.image?.drawInRect(CGRectMake(0,0,l8rView.frame.size.width, l8rView.frame.size.height), blendMode: CGBlendMode.Normal, alpha: 1)
        
        tempImageView.image?.drawInRect(CGRectMake(0,0,l8rView.frame.size.width, l8rView.frame.size.height), blendMode: CGBlendMode.Normal, alpha: opacity)
        
        faceView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        tempImageView.image = nil
        
        refreshButton.hidden = false
    }
}

