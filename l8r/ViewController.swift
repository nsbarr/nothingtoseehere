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
import OAuthSwift
import MobileCoreServices
import Alamofire
import ReachabilitySwift

struct LastPhotoRetriever {
    func queryLastPhoto(resizeTo size: CGSize?, queryCallback: (UIImage? -> Void)) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        //        fetchOptions.fetchLimit = 1 // This is available in iOS 9.
        
        if let fetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions) as? PHFetchResult {
            if let asset = fetchResult.firstObject as? PHAsset {
                let manager = PHImageManager.defaultManager()
                
                // If you already know how you want to resize,
                // great, otherwise, use full-size.
                let targetSize = size == nil ? CGSize(width: asset.pixelWidth, height: asset.pixelHeight) : size!
                
                // I arbitrarily chose AspectFit here. AspectFill is
                // also available.
                manager.requestImageForAsset(asset,
                                             targetSize: targetSize,
                                             contentMode: .AspectFit,
                                             options: nil,
                                             resultHandler: { image, info in
                                                
                                                queryCallback(image)
                })
            }
        }
    }
}

class PassThroughView: UIScrollView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.hidden && subview.alpha > 0 && subview.userInteractionEnabled && subview.pointInside(convertPoint(point, toView: subview), withEvent: event) {
                return true
            }
        }
        return true
    }
}


class MenuButton: UIButton {
    override init(frame: CGRect)  {
        super.init(frame: frame)
        self.adjustsImageWhenHighlighted = true //just putting this here to debug
        self.titleLabel!.font = UIFont(name: "PatrickHandSC-Regular", size: 24.0)
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
    
    override var highlighted: Bool {
        didSet {
            alpha = highlighted ? 0.6 : 1.0
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate, UIAlertViewDelegate,UIPickerViewDataSource, UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    
    //TODO: 3 THINGS
    // tap library icon to remove temp image if pulled from library
    // scroll view for long list of listss......
    // bigger button hitboxes
    
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
    let diameter:CGFloat = 30
    var refreshButton: UIButton!
    var g8rView = UIView()
    var connectButton: UIButton!
    var setupView = UIView()
    var setupImageView = UIImageView()
    var defaultFont = "PatrickHandSC-Regular"
    var defaultFontSize:CGFloat = 24.0
    
    var explainerText = UILabel()
    
    let imagePicker = UIImagePickerController()
    var libraryImageSelected = false


    
    //l8r setup
    var albumLabel:MenuButton!
    var l8rTagArray = NSUserDefaults.standardUserDefaults().objectForKey("SavedArray") as? [String] ?? [String]()
    var l8rImage = UIImage()
    var imageData = NSData()

    
    //draw setup
    var faceView = UIImageView()
    var tempImageView = UIImageView()
    var bottomView = UIView()
    var opacity:CGFloat = 0.8
    var swiped = false
    var canDraw = true
    var lastPoint = CGPoint.zero
    
    let softYellow = UIColor(red: 254/255, green: 235/255, blue: 157/255, alpha: 1)
    let softPink = UIColor(red: 229/255, green: 121/255, blue: 146/255, alpha: 1)
    var softGreen = UIColor(red: 136/255, green: 219/255, blue: 201/255, alpha: 1)
    
    let yellow = UIColor(red: 252/255, green: 250/255, blue: 0/255, alpha: 1)
    let pink = UIColor(red: 255/255, green: 0/255, blue: 173/255, alpha: 1)
    let green = UIColor(red: 31/255, green: 255/255, blue: 35/255, alpha: 1)
    let blue = UIColor(red: 0/255, green: 209/255, blue: 255/255, alpha: 1)
    
    
    var brushWidth:CGFloat = 10.0
    var currentColor = UIColor(red: 255/255, green: 0/255, blue: 173/255, alpha: 1)
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
    
    
    //trello setup
    // 1
    let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    // 2
    var dataTask: NSURLSessionDataTask?
    
    //
    var items = [UserObject]()
    var trelloListDict:[String:String] = [:]
    var pickerView = UIPickerView()
    var pickerData: [String] = [String]()
    var boardList = [String: String]()
    var cardId = ""
    
    var trelloToken = NSUserDefaults.standardUserDefaults().objectForKey("TrelloToken") as? String
    var trelloBoard = NSUserDefaults.standardUserDefaults().objectForKey("TrelloBoard") as? String
    

    


    //  MARK: - View Setup
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: - to troubleshoot token
      //  self.resetToken()
        
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        imagePicker.delegate = self
        
        
        if trelloToken == nil{
            self.showSetupView()
        }
        else {
            self.showNormalView()
        }


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
        
        let possibleCameraInput: AnyObject?
        do {
            possibleCameraInput = try AVCaptureDeviceInput(device: backCameraDevice)
        } catch let error as NSError {
            NSLog("Error:\(error)")
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
    
    func showNormalView(){
        
        
        hudView = UIView(frame: self.view.frame)
        l8rView = UIView(frame: self.view.frame)
        
        self.view.addSubview(l8rView)
        self.view.addSubview(hudView)
        
        
        self.setUpCamera()
        
        
        l8rView.addSubview(faceView)
        l8rView.addSubview(tempImageView)
        
        self.updateDrawViews()
        
        self.addBottomButtons()
        self.addLeftSideButtons()
    }
    
    func addBottomButtons(){
        
        let yPos:CGFloat = 20
        
        
        snapButton = UIButton(frame: CGRect(x: 0, y: self.view.frame.height-(4*diameter-14), width: diameter*3, height: diameter*3))
        let buttonImage = UIImage(named: "snapButtonImage")
        snapButton.setImage(buttonImage, forState: .Normal)
        snapButton.setImage(UIImage(named:"snapButtonImageOpen"), forState: .Selected)
        snapButton.center.x = self.view.center.x
        snapButton.hidden = false
        snapButton.addTarget(self, action: #selector(ViewController.snapButtonTapped(_:)), forControlEvents: .TouchUpInside)
        hudView.addSubview(snapButton)
        
        let trelloButton = UIButton(frame: CGRect(x: self.view.frame.width-(diameter+16), y: snapButton.frame.maxY-diameter, width: diameter, height: diameter))
        trelloButton.setImage(UIImage(named: "trello"), forState: .Normal)
        //trelloButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        trelloButton.addTarget(self, action: #selector(ViewController.openTrello(_:)), forControlEvents: .TouchUpInside)
        trelloButton.layer.shadowColor = UIColor.blackColor().CGColor
        trelloButton.layer.shadowOffset = CGSizeMake(0, 1)
        trelloButton.layer.shadowOpacity = 1
        trelloButton.layer.shadowRadius = 1
        hudView.addSubview(trelloButton)
        
        
        let imagePickerButton = UIButton(frame: CGRect(x: 16, y: snapButton.frame.maxY-diameter, width: diameter, height: diameter))
        imagePickerButton.setImage(UIImage(named: "imagePicker"), forState: .Normal)
        //trelloButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        imagePickerButton.addTarget(self, action: #selector(ViewController.imagePickerTapped(_:)), forControlEvents: .TouchUpInside)
        imagePickerButton.layer.shadowColor = UIColor.blackColor().CGColor
        imagePickerButton.layer.shadowOffset = CGSizeMake(0, 1)
        imagePickerButton.layer.shadowOpacity = 1
        imagePickerButton.layer.shadowRadius = 1
        hudView.addSubview(imagePickerButton)
        
        
        //TODO: implement preview if we have photos permission. Also longtap to put it in
       // LastPhotoRetriever().queryLastPhoto(resizeTo: imagePickerButton.frame.size, queryCallback: UIImage? -> Void)

        

        


        

        
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
        g8rButton.addTarget(self, action: #selector(ViewController.showG8rView(_:)), forControlEvents: .TouchUpInside)
        g8rButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        g8rButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        g8rButton.titleLabel!.layer.shadowOpacity = 1
        g8rButton.titleLabel!.layer.shadowRadius = 1
        g8rButton.center.x = hudView.center.x
        
        var thisNewFrame = g8rButton.frame
        thisNewFrame.size.width += 16 //l + r padding
        thisNewFrame.size.height += 16
        //   button.titleEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)
        g8rButton.frame = thisNewFrame
        g8rButton.frame.origin.x -= 8
        g8rButton.frame.origin.y -= 8
        
        
        hudView.addSubview(g8rButton)
        

        
//        
//        let hideHudButton = UIButton(frame: CGRect(x: self.view.frame.width-(diameter+10), y: yPos, width: diameter, height: diameter))
//        hideHudButton.setTitle("🙈", forState: .Normal)
//        hideHudButton.setTitle("🐵", forState: .Selected)
//        hideHudButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
//        hideHudButton.addTarget(self, action: #selector(ViewController.toggleHud(_:)), forControlEvents: .TouchUpInside)
//        hideHudButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
//        hideHudButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
//        hideHudButton.titleLabel!.layer.shadowOpacity = 1
//        hideHudButton.titleLabel!.layer.shadowRadius = 1
//        self.view.addSubview(hideHudButton)
        

    }
    

    
    func leftSideButtonTapped(sender: UIButton){
        
        if sender.tag == 1{
            self.toggleKeyboard(sender)
        }
        else if sender.tag == 2{
            self.toggleColorPalettes(sender)
        }
        else if sender.tag == 3{
            self.toggleCamera(sender)
        }
        else if sender.tag == 4{
            self.toggleHud(sender)
        }
        else if sender.tag == 5{
            
        }
        else{
            print("learn to count you piece of 💩")
        }

    }
    
    func addLeftSideButtons(){
        
        //removing templates for now "📓", "📷",
        let arrayOfSideButtonNormalTitles = ["✏️","colorPalettePink","🌎","🐵"]
        let arrayOfSideButtonSelectedTitles = ["✏️","colorPaletteYellow","😎","🙈"]


        
        let initYPos = snapButton.frame.maxY-diameter
        let yBuff = diameter*2
        let xPos:CGFloat = 16
        
        for (index, value) in arrayOfSideButtonNormalTitles.enumerate(){
            let button = UIButton(frame: CGRectMake(xPos,initYPos-(yBuff*(CGFloat(index)+1)),diameter,diameter))
            button.setTitle(value, forState: .Normal)
            button.setTitle(arrayOfSideButtonSelectedTitles[index], forState: .Selected)
            button.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
            button.tag = index+1
            button.addTarget(self, action: #selector(ViewController.leftSideButtonTapped(_:)), forControlEvents: .TouchUpInside)
            button.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
            button.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
            button.titleLabel!.layer.shadowOpacity = 1
            button.titleLabel!.layer.shadowRadius = 1

            
            //for troubleshooting
//            button.layer.borderWidth = 1.0
//            button.layer.borderColor = UIColor.whiteColor().CGColor
            
            
            var thisNewFrame = button.frame
            thisNewFrame.size.width += 16 //l + r padding
            thisNewFrame.size.height += 16
        //   button.titleEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)
            button.frame = thisNewFrame
            button.frame.origin.x -= 8
            button.frame.origin.y -= 8
            
            
            if button.tag == 4{ //monkey
                self.view.addSubview(button)
                
            }
            else {
                hudView.addSubview(button)
            }
            
            if button.tag == 2{ //colorpalette
                button.setTitle("", forState: .Normal)
                button.setTitle("", forState: .Selected)
                button.setImage(UIImage(named: value), forState: .Normal)
                button.setImage(UIImage(named: arrayOfSideButtonSelectedTitles[index]), forState: .Selected)
                
            }
        }
        
        refreshButton = UIButton(frame: CGRect(x: xPos, y: initYPos-yBuff*(CGFloat(arrayOfSideButtonNormalTitles.count)+1), width: diameter, height: diameter))
        refreshButton.setTitle("🍃", forState: .Normal)
        refreshButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        refreshButton.addTarget(self, action: #selector(ViewController.refreshView(_:)), forControlEvents: .TouchUpInside)
        refreshButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        refreshButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        refreshButton.titleLabel!.layer.shadowOpacity = 1
        refreshButton.titleLabel!.layer.shadowRadius = 1
        refreshButton.hidden = true
        
        var thisNewFrame = refreshButton.frame
        thisNewFrame.size.width += 16 //l + r padding
        thisNewFrame.size.height += 16
        //   button.titleEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)
        refreshButton.frame = thisNewFrame
        refreshButton.frame.origin.x -= 8
        refreshButton.frame.origin.y -= 8
        
        hudView.addSubview(refreshButton)
        

        
//        bgButton = UIButton(frame: CGRect(x: 20, y: yPos, width: diameter, height: diameter))
//        bgButton.setTitle("📓", forState: .Normal)
//        bgButton.setTitle("📷", forState: .Selected)
//        bgButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
//        bgButton.addTarget(self, action: #selector(ViewController.toggleBg(_:)), forControlEvents: .TouchUpInside)
//        bgButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
//        bgButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
//        bgButton.titleLabel!.layer.shadowOpacity = 1
//        bgButton.titleLabel!.layer.shadowRadius = 1
//        hudView.addSubview(bgButton)
//        
//        let flipButton = UIButton(frame: CGRect(x: 80, y: yPos, width: diameter, height: diameter))
//        flipButton.setTitle("😎", forState: .Normal)
//        flipButton.setTitle("🌎", forState: .Selected)
//        flipButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
//        flipButton.addTarget(self, action: #selector(ViewController.toggleCamera(_:)), forControlEvents: .TouchUpInside)
//        flipButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
//        flipButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
//        flipButton.titleLabel!.layer.shadowOpacity = 1
//        flipButton.titleLabel!.layer.shadowRadius = 1
//        hudView.addSubview(flipButton)
//        
//        
//        let colorPaletteButton = UIButton(frame: CGRect(x: 140, y: yPos, width:diameter, height:diameter))
//        currentColor = pink
//        
//        colorPaletteButton.setImage(UIImage(named: "colorPalettePink"), forState: .Normal)
//        colorPaletteButton.setImage(UIImage(named:"colorPaletteYellow"), forState: .Selected)
//        
//        colorPaletteButton.addTarget(self, action: #selector(ViewController.toggleColorPalettes(_:)), forControlEvents: .TouchUpInside)
//        hudView.addSubview(colorPaletteButton)
//        
//        let textButton = UIButton(frame: CGRect(x: 200, y: yPos, width: diameter, height: diameter))
//        
//        textButton.setTitle("✏️", forState: .Normal)
//        textButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
//        textButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
//        textButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
//        textButton.titleLabel!.layer.shadowOpacity = 1
//        textButton.titleLabel!.layer.shadowRadius = 1
//        
//        textButton.addTarget(self, action: #selector(ViewController.toggleKeyboard(_:)), forControlEvents: .TouchUpInside)
//        hudView.addSubview(textButton)
        
    }
    
    func openTrello(sender: UIButton){
        print("card is \(cardId)")
        print("board is \(trelloBoard)")
        if cardId != ""{
            UIApplication.sharedApplication().openURL(NSURL(string:"https://trello.com/c/\(self.cardId)")!)

        }
        else{
            UIApplication.sharedApplication().openURL(NSURL(string:"https://trello.com/b/\(trelloBoard!)")!)

        }
    //    UIApplication.sharedApplication().openURL(NSURL(string:"jason://data/http://www.jasonbase.com/things/120.json")!)

        
    }
    
    func imagePickerTapped(sender: UIButton){
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        
        presentViewController(imagePicker, animated: true, completion: nil)
        
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

    
    func addTextView(){
        if textView == nil{
            textView = UITextView(frame: CGRectMake(10,10,self.view.frame.width, self.view.frame.height-70))
            textView.backgroundColor = UIColor.clearColor()
            textView.keyboardAppearance = UIKeyboardAppearance.Dark
            
            textView.returnKeyType = UIReturnKeyType.Done
            textView.userInteractionEnabled = true
            textView.delegate = self
            textView.autocorrectionType = UITextAutocorrectionType.No //workaround for not receiving touches on autocorrection
            
            
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
        
        let currentFontSize = textView.font?.pointSize
        if (textView.contentSize.height > textView.frame.size.height-210.0) { //TODO: Don't hardcode keyboard height or fontsize for that matter
            print("too tall!")
            var fontIncrement:CGFloat = 1
            while (textView.contentSize.height > textView.frame.size.height-210.0) {
                textView.font = UIFont(name: defaultFont, size: currentFontSize! - fontIncrement)
                fontIncrement = fontIncrement+1;
            }
        }
        else if (range.length==1 && text.characters.count==0 && currentFontSize < 38.0){
            print("backspace")
            if (textView.contentSize.height < textView.frame.size.height-210.0) { //TODO: Don't hardcode keyboard height or fontsize for that matter
                print("too small!")
                var fontIncrement:CGFloat = 1
                while (textView.contentSize.height < textView.frame.size.height-210.0) {
                    textView.font = UIFont(name: defaultFont, size: currentFontSize! + fontIncrement)
                    fontIncrement = fontIncrement+1;
                }
            }
        }
        
        
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
    
    // MARK: - Capture Behavior

    
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
        
        if (libraryImageSelected == true){
            
            
            if (sender.selected == true){ //remove the photo and hide the menu buttons
                self.clearCameraContents()
            }
            else { //show trello lists and select the sender
                
                self.showTrelloLists()
                
            }
            

            
        }
        
        else if !sender.selected{ //take the photo and show the list tags
            self.turnPreviewLayerIntoImage()
            self.previewLayer?.connection.enabled = false
         //   self.appearL8rLabels()
            self.showTrelloLists()
            
          //  self.getTrelloListsForFooBoard()
            
        }
        else{ //hide the list tags
            self.clearCameraContents()
        }
        
        sender.selected = !sender.selected // toggle icon


    }
    
    func showCreateListAlert(){
        
        var albumTextField: UITextField?
        let alert = UIAlertController(title: "Add a new list", message: "Create a list", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in
            textField.addTarget(self, action: "textChanged:", forControlEvents: .EditingChanged)
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
            let listName = albumTextField!.text!
            
            
            self.createNewTrelloListWithId(listName)
            
        }
        alert.addAction(defaultAction)
        (alert.actions[0] as UIAlertAction).enabled = false
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func textChanged(sender:AnyObject) {
        let tf = sender as! UITextField
        var resp : UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alert = resp as! UIAlertController
        (alert.actions[0] as UIAlertAction).enabled = (tf.text != "")
        print(tf.text)

    }
    
    // MARK: - Trello Behavior
    
    func showTrelloLists(){
        
        let reachability = try! Reachability.reachabilityForInternetConnection()
        
        if reachability.currentReachabilityStatus == .NotReachable {
            print("not connected")
            let alert = UIAlertView(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        } else {
            print("connected")
        }
        
        let oauthswift = OAuth1Swift(
            consumerKey:    "c2c5eeac5316244f7e1ee51d099e25f0",
            consumerSecret: "692a1675ff63e568d2b45b73ca60b53ae39e9000661c915267402098d6b3038b",
            requestTokenUrl: "https://trello.com/1/OAuthGetRequestToken",
            authorizeUrl:    "https://trello.com/1/OAuthAuthorizeToken?name=leightr&expiration=never&scope=read,write",
            accessTokenUrl:  "https://trello.com/1/OAuthGetAccessToken"
            
        )
        
        
        oauthswift.client.get("https://api.trello.com/1/boards/\(trelloBoard!)/lists?cards=open&card_fields=name&fields=name&key=c2c5eeac5316244f7e1ee51d099e25f0&token=\(trelloToken!)",
                              success: {
                                data, response in
                                
                                let jsonData = self.nsdataToJSON(data)
                                let jsonArray = jsonData as! NSArray

                                let labelHeight:CGFloat = 40
                                let yBuff:CGFloat = 20
                                var yInit = 1
                                
                                let newTagLabel = MenuButton(frame: CGRectMake(0,0,100,labelHeight))
                                newTagLabel.center.y = self.snapButton.frame.minY - (labelHeight+yBuff)
                                newTagLabel.setTitle("new list", forState: .Normal)
                                
                                newTagLabel.contentVerticalAlignment = .Center
                                newTagLabel.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
                                newTagLabel.sizeToFit()
                                newTagLabel.backgroundColor = self.softGreen
                                newTagLabel.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                                newTagLabel.frame.origin.x = self.snapButton.frame.maxX-(newTagLabel.frame.width)
                                var thisNewFrame = newTagLabel.frame
                                thisNewFrame.size.width += 20 //l + r padding
                                newTagLabel.frame = thisNewFrame
                                newTagLabel.frame.origin.x = self.view.frame.width-(newTagLabel.frame.width+16)
                              
                              //trying to get scroll view working
//                                let tempScrollView = UIScrollView(frame: CGRectMake(100,0, 100, self.hudView.frame.height-200))
//                                tempScrollView.backgroundColor = UIColor.redColor()
//                                print(tempScrollView.scrollEnabled)
//                                tempScrollView.delegate = self
//                                tempScrollView.contentSize = self.hudView.frame.size
//                                tempScrollView.scrollEnabled = true
//                                tempScrollView.userInteractionEnabled = true
//                                tempScrollView.flashScrollIndicators()
//                                self.hudView.addSubview(tempScrollView)
                    


                                
                                newTagLabel.addTarget(self, action: #selector(ViewController.trelloLabelPressed(_:)), forControlEvents: .TouchUpInside)
                                
                             //   tempScrollView.addSubview(newTagLabel)
                               self.hudView.addSubview(newTagLabel)
                                for list in jsonArray{
                                    let name = list["name"] as! String
                                    let id = list["id"] as! String
                                    self.trelloListDict[name] = id
                                    self.albumLabel = MenuButton(frame: CGRectMake(0,0,100,labelHeight))
                                    self.albumLabel.center.y = self.snapButton.frame.minY - ((labelHeight+yBuff)*CGFloat(1+yInit))
                                    self.albumLabel.setTitle(name, forState: .Normal)
                                    print(self.albumLabel.titleLabel)
                                    self.albumLabel.contentVerticalAlignment = .Center
                                    self.albumLabel.sizeToFit()
                                    var newFrame = self.albumLabel.frame
                                    newFrame.size.width += 20 //l + r padding
                                    yInit = yInit+1
                                    self.albumLabel.frame = newFrame
                                    
                                    
                                    
                                    self.albumLabel.frame.origin.x = self.view.frame.width-(self.albumLabel.frame.width+16)
                                    self.albumLabel.addTarget(self, action: #selector(ViewController.trelloLabelPressed(_:)), forControlEvents: .TouchUpInside)
                                   
                                 //   tempScrollView.addSubview(self.albumLabel)
                                    self.hudView.addSubview(self.albumLabel)


                                }
                               // print("this is the dict\(self.trelloListDict)")
                                
                                
                             
            }, failure: { error in
                print(error)
        })

    }
    
    func trelloLabelPressed(sender: UIButton){
        self.stampL8rForSharing()
        
        if sender.titleLabel?.text == "new list"{
            
            //    self.showCreateAlbumAlert()
            self.showCreateListAlert()
            // self.showG8rView()
        }
        
        else if let trelloListId = self.trelloListDict[sender.titleLabel!.text!]{
            print(trelloListId)
            self.postImageToTrelloList(l8rImage, list:trelloListId)
            
        }
        else{
            print("fuck this")
        }
        
        
        //    self.showCreateAlbumAlert()
            // self.showG8rView()

    }
    

    
    func postImageToTrelloList(image: UIImage, list: String){
        //board ID5739289879172eb3ff7c8892
        let oauthswift = OAuth1Swift(
            consumerKey:    "c2c5eeac5316244f7e1ee51d099e25f0",
            consumerSecret: "692a1675ff63e568d2b45b73ca60b53ae39e9000661c915267402098d6b3038b",
            requestTokenUrl: "https://trello.com/1/OAuthGetRequestToken",
            authorizeUrl:    "https://trello.com/1/OAuthAuthorizeToken?name=leightr&expiration=never&scope=read,write",
            accessTokenUrl:  "https://trello.com/1/OAuthGetAccessToken"
            
        )
        let dateFormatter = NSDateFormatter()
        let currentDate = NSDate()
    //    dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "'A l8r created 'dd/MM/yyyy' at 'hh:mm"
        let convertedDate = dateFormatter.stringFromDate(currentDate)
        

        
        var parameters: [String: AnyObject] = [
            "name" : convertedDate,
            "idList" : list,
            "token" : trelloToken!,
            "key" : "c2c5eeac5316244f7e1ee51d099e25f0"
            
        ]
        if textView != nil{
            if textView.text != ""{
                parameters["desc"] = textView.text
            }
            
        }

        
        oauthswift.client.post("https://trello.com/1/cards?pos=top", parameters: parameters,
                               success: {
                                data, response in
                                let dataArray = self.nsdataToJSON(data) as! NSDictionary
                                self.cardId = dataArray["id"] as! String
                                print(self.cardId)
                                self.attachImageToNewlyCreatedCard(self.cardId, image: image)
                                
                                
                                
            self.flashConfirm()
                                
                                
            }, failure: { (error) in
                print("post failed\(error)")
        })

    }
    
    func createNewTrelloListWithId(listName:String){
        let oauthswift = OAuth1Swift(
            consumerKey:    "c2c5eeac5316244f7e1ee51d099e25f0",
            consumerSecret: "692a1675ff63e568d2b45b73ca60b53ae39e9000661c915267402098d6b3038b",
            requestTokenUrl: "https://trello.com/1/OAuthGetRequestToken",
            authorizeUrl:    "https://trello.com/1/OAuthAuthorizeToken?name=leightr&expiration=never&scope=read,write",
            accessTokenUrl:  "https://trello.com/1/OAuthGetAccessToken"
        )
        
        let parameters: [String: AnyObject] = [
            "name" : listName,
            "idBoard" : trelloBoard!,
            "token" : trelloToken!,
            "key" : "c2c5eeac5316244f7e1ee51d099e25f0"
            
        ]
        
        oauthswift.client.post("https://trello.com/1/lists", parameters: parameters,
                               success: {
                                data, response in
                                let dataArray = self.nsdataToJSON(data) as! NSDictionary
                                print(dataArray)
                                let listId = dataArray["id"] as! String
                                print(listId)
                                
                                self.postImageToTrelloList(self.l8rImage, list: listId)
                                
            }, failure: { (error) in
                print("post failed\(error)")
        })


    }
    
    func getMemberIdFromTokenAndReturnBoads(token:String){
        
        let oauthswift = OAuth1Swift(
            consumerKey:    "c2c5eeac5316244f7e1ee51d099e25f0",
            consumerSecret: "692a1675ff63e568d2b45b73ca60b53ae39e9000661c915267402098d6b3038b",
            requestTokenUrl: "https://trello.com/1/OAuthGetRequestToken",
            authorizeUrl:    "https://trello.com/1/OAuthAuthorizeToken?name=leightr&expiration=never&scope=read,write",
            accessTokenUrl:  "https://trello.com/1/OAuthGetAccessToken"
            
        )
        
        connectButton.setTitle("Fetching Boards...", forState: .Normal)
        self.explainerText.text = ""
        
        
        oauthswift.client.get("https://api.trello.com/1/tokens/\(token)?key=c2c5eeac5316244f7e1ee51d099e25f0&token=\(token)",
                              success: {
                                data, response in
                                
                                let jsonData = self.nsdataToJSON(data)
                                let jsonDict = jsonData as! NSDictionary
                                
                                print("json is \(jsonDict)")
                                let idMember = String(jsonDict["idMember"])
                                print(idMember)
                                //TODO: figure out why memberID isn't working as a variable in there. Also, we shouldn't have to do the first call once we have the memberID; just save it so we can do 1 call
                                oauthswift.client.get("https://api.trello.com/1/members/54ef9a89772213529008b0a9/boards?memberships=all&organization=true&filter=all&key=c2c5eeac5316244f7e1ee51d099e25f0&token=\(token)",
                                    success: {
                                        data, response in
                                        
                                        let jsonDataAgain = self.nsdataToJSON(data)
                                        let jsonDictAgain = jsonDataAgain as! NSArray
                                        
                                        print("json is \(jsonDictAgain)")
                                        
                                        
                                        for board in jsonDictAgain{
                                            let name = board["name"] as! String
                                            let id = board["id"] as! String
                                            self.boardList[name] = id
                                            self.pickerData.append(name)
                                            
                                        }
                                        
                                        print(self.boardList)
                                        

                                        self.connectButton.hidden = true
                                        
                                        let enableCameraButton = MenuButton(frame: CGRectMake(0,0,100,100))
                                        enableCameraButton.setTitle("Start l8ring", forState: .Normal)
                                        enableCameraButton.contentVerticalAlignment = .Center
                                        enableCameraButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
                                        enableCameraButton.sizeToFit()
                                        enableCameraButton.backgroundColor = self.softGreen
                                        enableCameraButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                                        enableCameraButton.addTarget(self, action: #selector(ViewController.enableCameraButtonTapped(_:)), forControlEvents: .TouchUpInside)
                                        enableCameraButton.center = self.setupView.center
                                        enableCameraButton.frame.origin.y = 2*self.setupView.frame.height/3
                                        var newFrame = enableCameraButton.frame
                                        newFrame.size.width += 20 //l + r padding
                                        enableCameraButton.frame = newFrame
                                        self.setupView.addSubview(enableCameraButton)
                                        
                                        self.explainerText.text = "Rad. Now just pick your Board:"
                                        
                                        self.pickerView.backgroundColor = UIColor.clearColor()
                                        self.pickerView.frame = CGRectMake(0, 0, self.setupView.frame.width-40, 200)
                                        self.pickerView.center = self.setupView.center
                                    
                                        self.setupView.addSubview(self.pickerView)
                                        
                                        self.pickerView.hidden = false
                                        
                                        self.setupImageView.image = UIImage(named: "setupViewComplete")

                                        
                                        
                                        
                                        
                                        
                                    }, failure: { error in
                                        print(error)
                                })
                                
                                
                                
                                
            }, failure: { error in
                print(error)
        })
        
    }
    
    func enableCameraButtonTapped(sender: UIButton){
        //TODO: this is slow. and maybe we're adding views on views on views...
        canDraw = true
        if hudView.superview == nil{
            self.showNormalView()
        }
        setupView.removeFromSuperview()
        

    }
    
    func authTrello(){
        let oauthswift = OAuth1Swift(
            consumerKey:    "c2c5eeac5316244f7e1ee51d099e25f0",
            consumerSecret: "692a1675ff63e568d2b45b73ca60b53ae39e9000661c915267402098d6b3038b",
            requestTokenUrl: "https://trello.com/1/OAuthGetRequestToken",
            authorizeUrl:    "https://trello.com/1/OAuthAuthorizeToken?name=leightr&expiration=never&scope=read,write",
            accessTokenUrl:  "https://trello.com/1/OAuthGetAccessToken"
            
        )
        
        oauthswift.authorizeWithCallbackURL(
            NSURL(string: "l8r://oauth-callback/trello")!,
            success: { credential, response, parameters in
                print(credential.oauth_token)
                print(credential.oauth_token_secret)
                print(credential)
                print(parameters)
                NSUserDefaults.standardUserDefaults().setObject(credential.oauth_token, forKey: "TrelloToken")
                self.trelloToken = NSUserDefaults.standardUserDefaults().objectForKey("TrelloToken") as? String
                self.getMemberIdFromTokenAndReturnBoads(credential.oauth_token)
                
                
                
            },
            failure: { error in
                print(error.localizedDescription)
            }
        )
    }
    
    
    
    
    func attachImageToNewlyCreatedCard(card:String, image:UIImage){
        
        let dateFormatter = NSDateFormatter()
        let currentDate = NSDate()
//        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "yyyy-MM-dd 'at' hhmm"
        let convertedDate = dateFormatter.stringFromDate(currentDate)

        

        
        let parameters: [String: String] = [
            "mimeType" : "image/jpeg",
            "token" : trelloToken!,
            "key" : "c2c5eeac5316244f7e1ee51d099e25f0",
            "name" : "\(convertedDate).jpg"
            
        ]
        //holy shit this works
        
        let URL = "https://trello.com/1/cards/\(card)/attachments"
        
        
        Alamofire.upload(.POST, URL, multipartFormData: {
            multipartFormData in
            
            if let imageData = UIImageJPEGRepresentation(image, 0.5) {
                multipartFormData.appendBodyPart(data: imageData, name: "file", fileName: "file.png", mimeType: "image/png")
            }
            
            for (key, value) in parameters {
                multipartFormData.appendBodyPart(data: value.dataUsingEncoding(NSUTF8StringEncoding)!, name: key)
            }
            
            }, encodingCompletion: {
                encodingResult in
                
                switch encodingResult {
                case .Success(let upload, _, _):
                    print("it worked")
                case .Failure(let encodingError):
                    print(encodingError)
                }
        })
        
        
    }
    
    func resetToken(){
        //DO THIS TO RESET TOKEN
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "TrelloToken")
        trelloToken = NSUserDefaults.standardUserDefaults().objectForKey("TrelloToken") as? String
    }
    
    //MARK: - Setup View Settings
    func showSetupView(){
        canDraw = false
        
        setupView = UIView(frame: self.view.frame)
        setupImageView = UIImageView(frame: setupView.frame)
        
        self.view.addSubview(setupView)
        setupView.addSubview(setupImageView)
        connectButton = MenuButton(frame: CGRectMake(0,0,100,100))

        
        explainerText = UILabel(frame: CGRectMake(30,0,setupView.frame.width-30,400))
        explainerText.numberOfLines = 0
        explainerText.font = UIFont(name: defaultFont, size: defaultFontSize)
        explainerText.textColor = UIColor.blackColor()
        explainerText.frame.origin.y = 40
        explainerText.center.x = setupView.center.x
        explainerText.textAlignment = .Center
        explainerText.layer.shadowColor = UIColor.grayColor().CGColor
        explainerText.layer.shadowOffset = CGSizeMake(0, 1)
        explainerText.layer.shadowOpacity = 1
        explainerText.layer.shadowRadius = 1
        
        if trelloToken == nil{
            connectButton.hidden = false
            pickerView.hidden = true
            explainerText.text = "l8r makes it a snap to post to trello. \n \n \n \n \nUse it to capture tasks, ideas, food, inspiration...anything you want to revisit l8r!"
            setupImageView.image = UIImage(named: "setupView")
        }
        else{
            pickerView.hidden = false
            connectButton.hidden = true
            
            
            self.getMemberIdFromTokenAndReturnBoads(trelloToken!)
        }
        

        

        
        connectButton.setTitle("Connect to Trello", forState: .Normal)
        connectButton.contentVerticalAlignment = .Center
        connectButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
        connectButton.sizeToFit()
        connectButton.backgroundColor = softGreen
        connectButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        connectButton.addTarget(self, action: #selector(ViewController.connectButtonTapped(_:)), forControlEvents: .TouchUpInside)
        connectButton.center = setupView.center
        connectButton.frame.origin.y = 2*self.setupView.frame.height/3
        var newFrame = connectButton.frame
        newFrame.size.width += 20 //l + r padding
        connectButton.frame = newFrame
        connectButton.adjustsImageWhenHighlighted = true
        setupView.addSubview(connectButton)
        
        setupView.addSubview(explainerText)

        
        

        

        
    }

    
    //MARK: - G8R View Settings
    
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
        
        
        let infoLabel = UILabel(frame: CGRectMake(0,20,g8rView.frame.width, 40))
       // infoLabel.sizeToFit()
        infoLabel.text = "l8r • version: \(version) • bundle: \(appBundle)"
        infoLabel.font = UIFont(name: defaultFont, size: defaultFontSize)
        infoLabel.textColor = UIColor.whiteColor()
       // infoLabel.frame.origin.x = g8rView.frame.width-(infoLabel.frame.width+16)
        infoLabel.backgroundColor = UIColor.clearColor()
        infoLabel.textAlignment = .Center
       infoLabel.center = g8rView.center
        infoLabel.frame.origin.y = g8rView.frame.height - 60
        g8rView.addSubview(infoLabel)
        
        
        
        let twitterButton = MenuButton(frame: CGRectMake(0,0,100,100))
        twitterButton.setTitle("@l8rg8r", forState: .Normal)
        twitterButton.contentVerticalAlignment = .Center
        twitterButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
        twitterButton.sizeToFit()
        twitterButton.backgroundColor = blue
        twitterButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        twitterButton.addTarget(self, action: #selector(ViewController.openTwitterProfile(_:)), forControlEvents: .TouchUpInside)
        var newFrame = twitterButton.frame
        newFrame.size.width += 20 //l + r padding
        twitterButton.frame = newFrame
        twitterButton.center.x = g8rView.center.x
        g8rView.addSubview(twitterButton)
        twitterButton.frame.origin.y = g8rView.center.y - 100
        
        
        
        let dismissButton = MenuButton(frame: CGRectMake(0,0,100,100))
        dismissButton.setTitle("back to l8r", forState: .Normal)
        dismissButton.contentVerticalAlignment = .Center
        dismissButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
        dismissButton.sizeToFit()
        dismissButton.backgroundColor = softPink
        dismissButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        dismissButton.addTarget(self, action: #selector(ViewController.dismissG8rView(_:)), forControlEvents: .TouchUpInside)
        newFrame = dismissButton.frame
        newFrame.size.width += 20 //l + r padding
        dismissButton.frame = newFrame
        dismissButton.center.x = g8rView.center.x
        g8rView.addSubview(dismissButton)
        dismissButton.frame.origin.y = g8rView.center.y + 50
        
        
        
        let changeBoardButton = MenuButton(frame: CGRectMake(0,0,100,100))
        changeBoardButton.setTitle("Trello Settings", forState: .Normal)
        changeBoardButton.contentVerticalAlignment = .Center
        changeBoardButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
        changeBoardButton.sizeToFit()
        changeBoardButton.backgroundColor = softYellow
        changeBoardButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        changeBoardButton.addTarget(self, action: #selector(ViewController.changeBoardButtonTapped(_:)), forControlEvents: .TouchUpInside)
        newFrame = dismissButton.frame
        newFrame.size.width += 20 //l + r padding
        changeBoardButton.frame = newFrame
        changeBoardButton.center = g8rView.center
        g8rView.addSubview(changeBoardButton)

    
    }
    
    func changeBoardButtonTapped(sender: UIButton){
        self.dismissG8rView(sender)
        self.showSetupView()
        
    }
    
    func connectButtonTapped(sender: UIButton){
        self.authTrello()
        
    }
        

    
    func openTwitterProfile(sender: UIButton){
        UIApplication.sharedApplication().openURL(NSURL(string:"https://twitter.com/l8rapp")!)
    }
    
    func dismissG8rView(sender: UIButton){
        g8rView.removeFromSuperview()
        canDraw = true
    }
    
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            //TODO: Shitty way to remove the photo we just took
            if tempPreviewLayerView.superview != nil{
                print("removing old photo")
                tempPreviewLayerView.removeFromSuperview()
            }
            
            self.tempPreviewLayerView = UIImageView(frame: self.view.bounds)
            self.tempPreviewLayerView.contentMode = UIViewContentMode.ScaleAspectFill
            self.tempPreviewLayerView.image = pickedImage
            
            self.l8rView.insertSubview(tempPreviewLayerView, belowSubview: self.faceView)
            //TODO: this is going to be gross
            libraryImageSelected = true
            print("fuck yourself")
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    //MARK: - UIPicker Delegate Methods
    
    // The number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        let titleData = pickerData[row]
        let myAttribute = [NSFontAttributeName: UIFont(name: "ChalkboardSE-Regular", size: defaultFontSize)!]
        let myTitle = NSAttributedString(string: titleData, attributes: myAttribute)
        
        return myTitle
    }
    
    //MARK: - Unused PhotoAlbum Methods
    
    func showCreateAlbumAlert(){
    
    
    
        var albumTextField: UITextField?
        let alert = UIAlertController(title: "Cool Alert", message: "Name your Tag", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in
            
                let shuffled = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(self.placeholderTextArray)
                textField.placeholder = shuffled[0] as? String
           
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
    
    //
    //    func fetchListOfL8rAlbums(){
    //        let assetCollections = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumRegular, options: nil)
    //
    //        for i in 0..<assetCollections.count {
    //            if let assetCollection = assetCollections[i] as? PHAssetCollection {
    //
    //                let fetchOptions = PHFetchOptions()
    //                fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.Image.rawValue)
    //
    //
    ////                let assetsInCollection  = PHAsset.fetchAssetsInAssetCollection(assetCollection, options: fetchOptions)
    //
    //                if let localizedTitle = assetCollection.localizedTitle {
    //                    if localizedTitle.rangeOfString("l8r") != nil{
    //                        let l8rLessTitle = localizedTitle.stringByReplacingOccurrencesOfString("l8r", withString: "")
    //                        print(l8rLessTitle)
    //                    }
    //                }
    //            }
    //        }
    //
    //    }
    //
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
        
        newTagLabel.addTarget(self, action: #selector(ViewController.l8rLabelPressed(_:)), forControlEvents: .TouchUpInside)
        
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
        
        shareTagLabel.addTarget(self, action: #selector(ViewController.l8rLabelPressed(_:)), forControlEvents: .TouchUpInside)
        
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
                albumLabel.addTarget(self, action: #selector(ViewController.l8rLabelPressed(_:)), forControlEvents: .TouchUpInside)
                hudView.addSubview(albumLabel)
                
            }
        }
        else {
            print("can't show labels, array count is \(l8rTagArray.count)")
        }
        
    }
    
    
    

    

    

    
//MARK: - Flotsam & Jetsam
//    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        
//        if !searchBar.text!.isEmpty {
//            // 1
//            if dataTask != nil {
//                dataTask?.cancel()
//            }
//            // 2
//            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
//            // 3
//            let expectedCharSet = NSCharacterSet.URLQueryAllowedCharacterSet()
//            let searchTerm = searchBar.text!.stringByAddingPercentEncodingWithAllowedCharacters(expectedCharSet)!
//            // 4
//            let url = NSURL(string: "https://itunes.apple.com/search?media=music&entity=song&term=\(searchTerm)")
//            // 5
//            dataTask = defaultSession.dataTaskWithURL(url!) {
//                data, response, error in
//                // 6
//                dispatch_async(dispatch_get_main_queue()) {
//                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
//                }
//                // 7
//                if let error = error {
//                    print(error.localizedDescription)
//                } else if let httpResponse = response as? NSHTTPURLResponse {
//                    if httpResponse.statusCode == 200 {
//                  //      self.updateSearchResults(data)
//                    }
//                }
//            }
//            // 8
//            dataTask?.resume()
//        }
//    }
    

    
    

    
    
    
   

    
        
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
        libraryImageSelected = false
        if textView != nil{
            textView.text = ""
        }

        snapButton.selected = false
        
        for view in hudView.subviews {
            if view.isKindOfClass(MenuButton) || view.isKindOfClass(PassThroughView) {
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
                    
                    self.imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
               //     let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
                    
                    self.previewLayerImage = UIImage(data: self.imageData, scale: 1.0)!
                    
                    if !self.currentDeviceIsBack {
                        self.previewLayerImage = UIImage(CGImage: self.previewLayerImage.CGImage!, scale:self.previewLayerImage.scale, orientation: UIImageOrientation.LeftMirrored)
                        
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
    
    func clearCameraContents(){
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
        libraryImageSelected = false
        
    }
    
    func toggleCamera(sender: UIButton) {
        
        self.clearCameraContents()
        if currentDeviceIsBack {

            let possibleCameraInput: AnyObject?
            
            do {
                possibleCameraInput = try AVCaptureDeviceInput(device: frontCameraDevice)
            }
            catch let error as NSError {
                NSLog("Error:\(error)")
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

            let possibleCameraInput: AnyObject?
            do {
                possibleCameraInput = try AVCaptureDeviceInput(device: backCameraDevice)
            }
            catch let error as NSError {
                NSLog("Error:\(error)")
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
    
    
    
    
    
    
    // this function creates the required URLRequestConvertible and NSData we need to use Alamofire.upload
    func urlRequestWithComponents(urlString:String, parameters:Dictionary<String, String>, imageData:NSData) -> (URLRequestConvertible, NSData) {
        
        // create url request to send
        var mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        mutableURLRequest.HTTPMethod = Alamofire.Method.POST.rawValue
        let boundaryConstant = "myRandomBoundary12345";
        let contentType = "multipart/form-data;boundary="+boundaryConstant
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        
        
        // create upload data to send
        let uploadData = NSMutableData()
        
        // add image
        uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData("Content-Disposition: form-data; name=\"file\"; filename=\"file.png\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData("Content-Type: image/png\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData(imageData)
        
        // add parameters
        for (key, value) in parameters {
            uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            uploadData.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        uploadData.appendData("\r\n--\(boundaryConstant)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        
        // return URLRequestConvertible and NSData
        return (Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: nil).0, uploadData)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        print(pickerData[row])
        let boardName = pickerData[row]
        print(boardList[boardName])
        NSUserDefaults.standardUserDefaults().setObject(boardList[boardName], forKey: "TrelloBoard")
        
        trelloBoard = NSUserDefaults.standardUserDefaults().objectForKey("TrelloBoard") as? String

        
    }
    

    
        
        




    func nsdataToJSON(data: NSData) -> AnyObject? {
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
        } catch let myJSONError {
            print(myJSONError)
        }
        return nil
    }

    
    
    
    //MARK: - Drawing Controls
    
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
            // drawLineFrom(lastPoint, toPoint: lastPoint)
        }
        
        else if canDraw{
        
            UIGraphicsBeginImageContext(faceView.frame.size)
            
            faceView.image?.drawInRect(CGRectMake(0,0,l8rView.frame.size.width, l8rView.frame.size.height), blendMode: CGBlendMode.Normal, alpha: 1)
            
            tempImageView.image?.drawInRect(CGRectMake(0,0,l8rView.frame.size.width, l8rView.frame.size.height), blendMode: CGBlendMode.Normal, alpha: opacity)
            
            faceView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            tempImageView.image = nil
            
            refreshButton.hidden = false
        }
        
    }
}



//MARK: - Extensions



extension NSCharacterSet {
    class func URLParameterValueCharacterSet() -> NSCharacterSet {
        let characterSet = NSMutableCharacterSet.alphanumericCharacterSet()
        characterSet.addCharactersInString("-._~")
        
        return characterSet
    }
}

extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}
