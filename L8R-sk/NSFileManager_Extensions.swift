//
//  NSFileManager_Extensions.swift
//  l8r
//
//  Created by Diego Doval on 1/7/16.
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation
import SpriteKit
import CoreGraphics
extension NSFileManager {
    class func directoryExistsAtURL(dirURL:NSURL) -> Bool {
        NSFileManager.defaultManager().fileExistsAtPath(dirURL.absoluteString)
        return false
    }
    
    class func createDirectoryAtURL(dirURL:NSURL) {
        if !NSFileManager.directoryExistsAtURL(dirURL) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(dirURL, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError {
                NSLog("Error creating dir \(dirURL) = \(error)")
            }
        }
    }
    
    class func deleteFileAtURL(url:NSURL) {
        if !NSFileManager.defaultManager().fileExistsAtPath(url.absoluteString) {
            NSLog("Error, trying to delete file at \(url) but it doesn't exist, ignoring.")
            return
        }
        
        do {
            try NSFileManager.defaultManager().removeItemAtURL(url)
        }
        catch let error as NSError {
            NSLog("Error deleting file dir \(url) = \(error)")
        }
    }
    
    class func saveImage(image:UIImage, toURL targetURL:NSURL) {
        if let data = UIImageJPEGRepresentation(image, 0.75) {
            data.writeToURL(targetURL, atomically: true)
        }
        else {
            NSLog("Error writing image, to \(targetURL), ignoring.")
        }
    }
    
    class func loadImage(fromURL imageURL:NSURL) -> UIImage! {
        if let data = NSData(contentsOfURL: imageURL) {
            return UIImage(data: data)
        }
        else {
            NSLog("Error loading image, could not read image NSData from \(imageURL), returning nil")
        }
        return nil
      
    }
}
