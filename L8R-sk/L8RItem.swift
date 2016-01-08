//
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation
import SpriteKit


public func==(rhs:L8RItem, lhs:L8RItem) -> Bool {
    return rhs.UUID == lhs.UUID
}

public class L8RItem: NSObject, NSCoding {

    static let commonImagePath:NSURL = L8RDirectory.sharedInstance.directory("images")
    
    var UUID:String
    var createdDate:NSDate
    var tag:String!
    var text:String!
    var hasImage:Bool = false
    var imagePath:NSURL! {
        if !hasImage {
            return nil
        }
        
        return L8RItem.commonImagePath.URLByAppendingPathComponent(self.UUID)
    }
    
    public init(date:NSDate) {
        self.createdDate = date
        //TODO add error management, in principle this should never fail
        self.UUID = String.createUUIDString()!
    }
    
    public required init(coder decoder: NSCoder) {
        self.UUID = decoder.decodeObjectForKey("UUID") as! String
        self.createdDate = decoder.decodeObjectForKey("createdDate") as! NSDate
        self.text = decoder.decodeObjectForKey("text") as? String
        self.hasImage = decoder.decodeBoolForKey("hasImage")
    }
    
    //sets the image asynchronously
    func setImage(image:UIImage!) {
        if image == nil {
            //delete file, set my path to nil
            if hasImage {
                NSFileManager.deleteFileAtURL(self.imagePath!)
                hasImage = false
            }
            return
        }
        
        self.hasImage = true
        NSFileManager.saveImage(image, toURL: self.imagePath)
    }
    
    func removeImage() {
        self.setImage(nil)
    }
    
    ///load image asynchronously
    func loadImage(completionBlock:((image:UIImage!) -> Void)) {

        NSThread.dispatchAsyncInBackground { () -> Void in
            var image:UIImage!
            if self.hasImage {
                image = NSFileManager.loadImage(fromURL: self.imagePath)
            }
            completionBlock(image: image)
        }
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.UUID, forKey: "UUID")
        coder.encodeObject(self.createdDate, forKey: "createdDate")
        coder.encodeObject(self.text, forKey: "text")
        coder.encodeBool(self.hasImage, forKey: "hasImage")
    }
    
    public override var hashValue:Int {
        return self.UUID.hashValue
    }
    
    override public var description:String {
        let textToPrint:String = (text != nil) ? text:"<empty>"
        let imPath:String = (text != nil) ? text:"<no image path>"
        return "L8RItem:\n\tCreated: \(createdDate)\n\tUUID: \(UUID)\n\tText:[\(textToPrint)]\n\tImage Path:[\(imPath)]"
    }
}