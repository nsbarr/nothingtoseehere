import Foundation
import SpriteKit
import AVFoundation

public class PhotoCameraController : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {


    public var lastFrame:SKTexture!
    
    var lastFrameReceivedAt:NSTimeInterval = 0
    
    var cameraFrameQueue = dispatch_queue_create("l8r.camera.frameQueue", DISPATCH_QUEUE_CONCURRENT);
    var isUpdatingCameraFrame:Bool = false
    
    var backCameraDevice:AVCaptureDevice!
    var frontCameraDevice:AVCaptureDevice?
    var stillImageOutput:AVCaptureStillImageOutput!
    var session:AVCaptureSession!
    var currentInput: AVCaptureDeviceInput?
    var currentDeviceIsBack = true
    var sessionQueue:dispatch_queue_t!
    
    var videoOutput:AVCaptureVideoDataOutput!
    

    public override init() {
        
    }
    
    var imV:UIImageView!
    
    func updateLastFrame(texture:SKTexture) {

        dispatch_barrier_sync(self.cameraFrameQueue, { () -> Void in
            self.isUpdatingCameraFrame = true
            defer {
                self.isUpdatingCameraFrame = false
            }
            self.lastFrame = texture//UIImage(CGImage: cgImage)
            self.hasFrameData = true
        })
    }
    
    public func retrieveLastFrame(retrieveBlock:((image: SKTexture?) -> Void)) {
        dispatch_barrier_async(cameraFrameQueue, { () -> Void in
//            if self.isUpdatingCameraFrame {
//                return
//            }

            let image = self.lastFrame
            
            NSThread.dispatchAsyncOnMainQueue() {
                retrieveBlock(image: image)
            }
        })
    }
    
    public var hasFrameData:Bool = false
    
    public func teardownCamera() {
        
        dispatch_async(sessionQueue, {
            self.session.stopRunning()
            self.session.removeOutput(self.videoOutput)
            self.session.removeOutput(self.stillImageOutput)
            self.videoOutput = nil
            self.stillImageOutput = nil
            self.session = nil
            //            NSNotificationCenter.defaultCenter().removeObserver(self.runtimeErrorHandlingObserver)
        })
    }
    
    
    public func checkCameraAccess(completion:((accessGranted:Bool) -> Void)) {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {
            (granted: Bool) -> Void in
            
            completion(accessGranted: granted)
            
        });
    }
    
    public func prepareCamera() {
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
        
        do {
            
            let desiredFrameRate:Double = 32

            if let formats = backCameraDevice.formats as? [AVCaptureDeviceFormat] {
                for format:AVCaptureDeviceFormat in formats {
                    if CMFormatDescriptionGetMediaSubType(format.formatDescription) ==
                        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                            
                            if let frameRateRanges = format.videoSupportedFrameRateRanges as? [AVFrameRateRange] {
                                var found:Bool = false
                                for range:AVFrameRateRange in frameRateRanges  {
                                    if range.maxFrameRate >= desiredFrameRate {
                                        NSLog("Format Selected = \(format.formatDescription) \n\tMin frame rate = \(range.minFrameRate)\n\tMax frame rate=\(range.maxFrameRate)")
                                        try backCameraDevice!.lockForConfiguration()
                                        backCameraDevice.activeFormat = format
                                        backCameraDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(desiredFrameRate), flags: CMTimeFlags.Valid, epoch: CMTimeEpoch(0))
                                        backCameraDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(desiredFrameRate), flags: CMTimeFlags.Valid, epoch: CMTimeEpoch(0))
                                        backCameraDevice!.unlockForConfiguration()
                                        print("Frame rate set at \(desiredFrameRate) fps")
                                        found = true
                                        break

                                    }
                                }
                                if found {
                                    break
                                }
                            }
                    }
                }
            }
            
            
            
        }
        catch let error {
            NSLog("Error: \(error)")
        }
        
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("com.l8r.camera.SampleBufferDelegateQueue", DISPATCH_QUEUE_SERIAL))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]

        if session.canAddOutput(self.videoOutput) {
            session.addOutput(self.videoOutput)
        }
        if let videoBufferConnection = videoOutput.connectionWithMediaType(AVMediaTypeVideo) {
            videoBufferConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            
        }
        
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
        if let buffer = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            buffer.videoOrientation = AVCaptureVideoOrientation.Portrait
        }

        //        let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
        //        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
        
        //this auto-handles focus, WB, exposure, etc.
//        session.sessionPreset = AVCaptureSessionPresetHigh// AVCaptureSessionPresetPhoto
        
        sessionQueue = dispatch_queue_create("com.l8r.camera.captureSession", DISPATCH_QUEUE_SERIAL)
        dispatch_async(sessionQueue) { () -> Void in
            self.session.startRunning()
        }
    }
    
    func takePhoto(completion:((image:UIImage?, metadata:NSDictionary?) -> Void)) {
        dispatch_async(sessionQueue) { () -> Void in
            
            let connection = self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
            
            // update the video orientation to the device one
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
            
            self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(connection) {
                (imageDataSampleBuffer, error) -> Void in
                
                if error == nil {
                    
                    // if the session preset .Photo is used, or if explicitly set in the device's outputSettings
                    // we get the data already compressed as JPEG
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    
                    // the sample buffer also contains the metadata, in case we want to modify it
                    let metadata:NSDictionary? = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
                    
                    NSThread.dispatchAsyncOnMainQueue() {
                        completion(image: UIImage(data: imageData), metadata: metadata)
                    }
                }
                else {
                    NSLog("error while capturing still image: \(error)")
                }
            }
        }
    }
    
    /*
    Captures camera output and places it in the lastFrame property, which can be used in the update
    method to show what the camera is seeing in an arbitrary surface, like an SKTexture on an SKSpriteNode
    We resize the image used to show what the camera is displaying to only 640 width (and corresponding scaled height)
    to minimize memory usage.
    Only one image from the camera is in memory at any one time.
    
    
    TODO add the ability to ignore the output altogether, ie when the camera is not visible this method should just not collect data at all or do it very infrequently at a minimum.
    */
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let time = CACurrentMediaTime()
        let frameTimeDif = time - lastFrameReceivedAt
        lastFrameReceivedAt = time
//        print("Frames received every \(frameTimeDif) sec")

//        let processTimeStart = CACurrentMediaTime()
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            var pixelBuffer = imageBuffer
            
            let val = CVPixelBufferLockBaseAddress(imageBuffer, 0);

            if val == kCVReturnSuccess {
                let sourceBaseAddr = CVPixelBufferGetBaseAddress( pixelBuffer )
                let colorspace = CGColorSpaceCreateDeviceRGB()
//                let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
                
                let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);

                let width = CVPixelBufferGetWidth(imageBuffer);
                let height = CVPixelBufferGetHeight(imageBuffer);
                let provider = CGDataProviderCreateWithData( &pixelBuffer, sourceBaseAddr, bytesPerRow * height, ReleaseCVPixelBuffer) //
                if let image = CGImageCreate(width, height, 8, 32, bytesPerRow, colorspace, CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue), provider, nil, true, CGColorRenderingIntent.RenderingIntentDefault) {

                    let tex = SKTexture(CGImage: image)

                    updateLastFrame(tex)
                }


            }
//            let processTimeEnd = CACurrentMediaTime()
//            print("Frames received every \(frameTimeDif) sec, processing time = \(processTimeEnd-processTimeStart)")
        
        }
        
    }

}

func ReleaseCVPixelBuffer(pixel:UnsafeMutablePointer<Void>, data:UnsafePointer<Void>, size:Int) -> Void {
//    print("xx")
    let infoPtr = UnsafeMutablePointer<CVPixelBufferRef>(pixel)

    CVPixelBufferUnlockBaseAddress(infoPtr.memory, 0)
//   infoPtr.destroy()

}
