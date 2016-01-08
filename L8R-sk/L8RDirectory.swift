//
//  L8RDirectory.swift
//  l8r
//
//  Created by Diego Doval on 1/7/16.
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation


class L8RDirectory {
    static let sharedInstance = L8RDirectory(directory: STANDARD_ITEM_SET_PATH)
    
    var path:NSURL
    
    class var STANDARD_ITEM_SET_PATH:NSURL {
        let paths = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsURL = paths[0]
        let path = documentsURL.URLByAppendingPathComponent("l8r")
        return path
    }
    
    init(directory:NSURL) {
        self.path = directory
    }
    
    func file(fileName:String) -> NSURL {
        return self.path.URLByAppendingPathComponent(fileName)
    }
    
    func directory(directoryName:String) -> NSURL {
        let dir = self.path.URLByAppendingPathComponent(directoryName)
        NSFileManager.createDirectoryAtURL(dir)
        return dir
    }
}