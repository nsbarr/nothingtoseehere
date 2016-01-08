import Foundation
import SpriteKit
import AVFoundation

public class PhotoCameraController : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {


    public var lastFrame:CGImageRef!
    public var lastFrameSize:CGSize!
    
    var cameraFrameQueue = dispatch_queue_create("l8r.camera.frameQueue", DISPATCH_QUEUE_CONCURRENT);
    var isUpdatingCameraFrame:Bool = false
    
    var backCameraDevice:AVCaptureDevice?
    var frontCameraDevice:AVCaptureDevice?
    var stillImageOutput:AVCaptureStillImageOutput!
    var session:AVCaptureSession!
    var currentInput: AVCaptureDeviceInput?
    var currentDeviceIsBack = true
    var sessionQueue:dispatch_queue_t!
    var tempPreviewLayerView = UIImageView()
    
    var previewLayerImage = UIImage()
    
    var videoOutput:AVCaptureVideoDataOutput!
    
    public override init() {
        
    }
    
    public func retrieveLastFrame(retrieveBlock:((image: CGImageRef?, size:CGSize?) -> Void)) {
        dispatch_barrier_sync(cameraFrameQueue, { () -> Void in
            if self.isUpdatingCameraFrame {
                return
            }
            self.isUpdatingCameraFrame = true
            defer {
                self.isUpdatingCameraFrame = false
            }

            let image = self.lastFrame
            let size = self.lastFrameSize
            
            NSThread.dispatchAsyncOnMainQueue() {
                retrieveBlock(image: image, size: size )
            }
        })
    }
    
    public var hasFrameData:Bool = false
    
    public func teardownCamera() {
        dispatch_async(sessionQueue, {
            self.session.stopRunning()
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
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("com.l8r.camera.SampleBufferDelegateQueue", DISPATCH_QUEUE_SERIAL))
        videoOutput.alwaysDiscardsLateVideoFrames = true
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
        
        //        let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
        //        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
        
        //this auto-handles focus, WB, exposure, etc.
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
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
    
    TODO measure performance to see if the calls to the dispatch barrier are piling up or if they are being processed fast enough to not be overwhelmed by the camera
    
    TODO add the ability to ignore the output altogether, ie when the camera is not visible this method should just not collect data at all or do it very infrequently at a minimum.
    */
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        dispatch_barrier_async(cameraFrameQueue, { () -> Void in
            if self.isUpdatingCameraFrame {
                return
            }
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                //turn the same buffer into a CoreImage image (CIImage) so that we can apply a filter to it.
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
                let cgImageSize = CGSize(width: nWidth, height: nHeight)
                
                self.lastFrame = cgImage
                self.lastFrameSize = cgImageSize

                self.hasFrameData = true
            }
            
            
            
        })
    }

}