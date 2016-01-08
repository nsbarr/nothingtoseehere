//
//  Copyright (c) 2016 poemsio. All rights reserved.
//

import SpriteKit
import AVFoundation

class L8RScene: SKScene, UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    //iPhone 6
    var scale: CGFloat!
    
    var l8rScroller: L8RSKScrollerNode!
    var l8rItemSet: L8RItemSet!
    
    var cameraFrameQueue = dispatch_queue_create("l8r.cameraQueue", DISPATCH_QUEUE_CONCURRENT);
    var lastFrame:CGImageRef!
    var lastFrameRect:CGRect!
    
    var backgroundNode:SKNode!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.whiteColor()
        self.scaleMode = .AspectFill

//        self.scale = self.size.width / 320.0
        
//        NSLog("SZ = \(self.size)")
        self.l8rScroller = L8RSKScrollerNode(size: self.size)
        self.l8rScroller.position = self.size.center
        self.l8rScroller.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        self.addChild(self.l8rScroller)
        
        
        var start = NSDate().timeIntervalSince1970
        let secInDay:NSTimeInterval = 86400
        start = start - (secInDay*4)
        
        NSLog("L8RScene created")

    }
    
    func loadItems(itemSet:L8RItemSet) {
        l8rItemSet = itemSet
        for item in itemSet.allItemsSortedByDate {
            self.l8rScroller.addItem(item)
        }
    }
    
    
    func returnToToday() {
        
        self.l8rScroller.scrollToToday()
    }
    
    
    func testScrolling() {
        var count = 0
        let items = l8rItemSet.allItemsSortedByDate
        delay(5) {
            for item in items {
                delay(NSTimeInterval(count * 2)) {
                    self.l8rScroller.scrollToItem(item)
                }
                count++
            }
        }
        let todayItems = l8rItemSet.itemsForToday
        if todayItems.count > 0 {
            delay(NSTimeInterval(items.count * 2 + 2)) {
                self.l8rScroller.scrollToItem(todayItems.first!)
            }
        }
        
    }
    
    override func didMoveToView(view: SKView) {
        
        

        view.addSwipeGestureRecognizer(UISwipeGestureRecognizer(target: self, action: "swipeGesture:"), direction: .Left)
        view.addSwipeGestureRecognizer(UISwipeGestureRecognizer(target: self, action: "swipeGesture:"), direction: .Right)

        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "longPressGesture:")
        longPressRecognizer.minimumPressDuration = 0.25
        view.addGestureRecognizer(longPressRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapGesture:")
        view.addGestureRecognizer(tapRecognizer)

        
    }
    
    func tapGesture(recognizer:UITapGestureRecognizer) {
        if recognizer.state == .Ended {
            let pv = recognizer.locationInView(view)
            let position = scene!.convertPointFromView(pv)
            let intersectingNodes = scene!.nodesAtPoint(position)
//            dump(intersectingNodes)
            for node in intersectingNodes {
                if node.reactsToTap {
                    let nodePosition = self.convertPoint(position, toNode: node)
                    //if gesture was 'consumed', return
                    if node.processTap(atPosition:nodePosition, recognizer:recognizer) {
                        return
                    }
                }
            }

            
        }
    }
    
    var longPressPreviousPosition:CGPoint!
    var longPressOriginalScrollerPosition:CGPoint!
    
    func longPressGesture(gesture:UILongPressGestureRecognizer) {
        
        if gesture.state == .Began {
            longPressPreviousPosition = gesture.locationInView(view)
            longPressOriginalScrollerPosition = self.l8rScroller.position
        }
        else if gesture.state == .Changed {
            let newPos = gesture.locationInView(view)
            let difX = newPos.x - longPressPreviousPosition.x

            if difX != 0 {
                self.l8rScroller.adjustPositionXBy(difX)
            }
            
            longPressPreviousPosition = newPos
            
        }
        else if gesture.state == .Ended {
            longPressPreviousPosition = nil
            let action = SKAction.moveTo(longPressOriginalScrollerPosition, duration: 0.5)
            action.timingMode = SKActionTimingMode.EaseOut
            self.l8rScroller.runAction(action)
            longPressOriginalScrollerPosition = nil
        }
       
    }
    
    func swipeGesture(rec:UISwipeGestureRecognizer) {
//        let location = touch.locationInNode(self)
//        let prevLocation = touch.previousLocationInNode(self)
        var difX:CGFloat = 0
        if rec.direction == .Left {
            difX = -self.l8rScroller.swipeIncrement
        }
        else if rec.direction == .Right {
            difX = self.l8rScroller.swipeIncrement
        }
        
        if difX != 0 {
            let act = SKAction.moveBy(CGVector(dx: difX, dy: 0), duration: 0.25)
            act.timingMode = .EaseIn
            self.l8rScroller.runAction(act)
        }
    }
    var lastUpdate:NSTimeInterval = 0
    var isUpdatingCameraFrame:Bool = false
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        let time = CACurrentMediaTime()
        
        if (time - lastUpdate) > (1.0/30.0) { //this is processed up to 30 times per second
            lastUpdate = time
            if self.l8rScroller != nil && self.lastFrame != nil && self.lastFrameRect != nil {
            dispatch_barrier_sync(cameraFrameQueue, { () -> Void in
                if self.isUpdatingCameraFrame {
                    return
                }
                self.isUpdatingCameraFrame = true
                self.l8rScroller.updateCameraFrame(self.lastFrame, imageRect: self.lastFrameRect)
                self.isUpdatingCameraFrame = false
            })
            }
        }
    }
    
    //MARK: Camera Stuff
    
    
    //camera setup

    var backCameraDevice:AVCaptureDevice?
    var frontCameraDevice:AVCaptureDevice?
    var stillImageOutput:AVCaptureStillImageOutput!
    var session:AVCaptureSession!
    var currentInput: AVCaptureDeviceInput?
    var currentDeviceIsBack = true
    var sessionQueue = dispatch_queue_create("com.example.camera.capture_session", DISPATCH_QUEUE_SERIAL)
    var tempPreviewLayerView = UIImageView()
    
    var previewLayerImage = UIImage()
    
    var videoOutput:AVCaptureVideoDataOutput!
    
    
    func teardownCamera() {
        dispatch_async(sessionQueue, {
            self.session.stopRunning()
//            NSNotificationCenter.defaultCenter().removeObserver(self.runtimeErrorHandlingObserver)
        })
    }

    
    func setupCamera() {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {
            (granted: Bool) -> Void in
            // If permission hasn't been granted, notify the user.
            if !granted {
                dispatch_async(dispatch_get_main_queue(), {
                    UIAlertView(
                        title: "Could not use camera!",
                        message: "L8R needs access to the camera, please check your privacy settings.",
                        delegate: self,
                        cancelButtonTitle: "OK").show()
                })
            }
            else {
                self.prepareCamera()
            }
        });
    }
    
    func prepareCamera() {
        let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableCameraDevices as! [AVCaptureDevice] {
            if device.position == .Back {
                backCameraDevice = device
            }
            else if device.position == .Front {
                frontCameraDevice = device
            }
        }
        
        self.session = AVCaptureSession()

        
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
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate queue", DISPATCH_QUEUE_SERIAL))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(self.videoOutput) {
            session.addOutput(self.videoOutput)
        }
        if let videoBufferConnection = videoOutput.connectionWithMediaType(AVMediaTypeVideo) {
            videoBufferConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
        }
//        let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
//        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!

        //this auto-handles focus, WB, exposure, etc.
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        sessionQueue = dispatch_queue_create("com.example.camera.capturessession", DISPATCH_QUEUE_SERIAL)
        dispatch_async(sessionQueue) { () -> Void in
            self.session.startRunning()
        }
    }
    
    func addStillImageOutput() {
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
    }
    
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {

        dispatch_barrier_async(cameraFrameQueue, { () -> Void in
            if self.isUpdatingCameraFrame {
                return
            }
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let ciImage = CIImage(CVPixelBuffer: imageBuffer)

                let width = CVPixelBufferGetWidth(imageBuffer)
                let height = CVPixelBufferGetHeight(imageBuffer)
                
                let nWidth = 640 //target iphone5 screen @2x
                let nHeight = Int(640 * (height / width))
                let xRatio = Float(nWidth.cgf / width.cgf)

                let resizeFilter = CIFilter(name: "CILanczosScaleTransform", withInputParameters: ["inputImage": ciImage, "inputAspectRatio": NSNumber(float: 1), "inputScale" : NSNumber(float:xRatio)])
                let resizedImage = resizeFilter!.outputImage
                
                let context = CIContext(options: nil)

                let cgImage = context.createCGImage(resizedImage!, fromRect: resizedImage!.extent)
                let cgImageRect = CGRect(x: 0, y: 0, width: nWidth, height: nHeight)

                self.lastFrame = cgImage
                self.lastFrameRect = cgImageRect
            }
            
            
            
            })
    }
    
}
