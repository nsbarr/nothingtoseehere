//
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation
import SpriteKit


class L8RItemSet {
    
    
    static let sharedInstance = L8RItemSet()

    var dataPathURL:NSURL!
    
    private var allItemsSet:Set<L8RItem> = Set<L8RItem>()
    
    ///will be notified when an item is added to the set via createItemWithImage(). If the image is available at that point it is passed on to avoid having to load it again, since presumably the callback is to update the UI
    var itemCreatedCallback:((item:L8RItem, image:UIImage?) -> Void)!
    
    init() {

    }
    
    func setStandardPath() {
        self.dataPathURL = L8RDirectory.sharedInstance.file("l8r.data")
        NSLog("L8R path set to: \(self.dataPathURL.absoluteString)")
    }
    
    func save() {
        
        if self.dataPathURL == nil {
            //no-op when path is nil
            return
        }
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(self.allItemsSet)
        
        let success = data.writeToURL(self.dataPathURL, atomically: true)

        if !success {
            NSLog("Error trying to write L8RItemSet to of \(self.dataPathURL.absoluteString)!")
        }

    }
    
     func load() {
        
        if self.dataPathURL == nil {
            //no-op when path is nil
            return
        }
        
        var error:NSError?
        
        let fileExists = self.dataPathURL.checkResourceIsReachableAndReturnError(&error)
        
        if fileExists {
            if let data = NSData(contentsOfURL: self.dataPathURL) {
                self.allItemsSet = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! Set<L8RItem>
            }
            else {
                NSLog("Could not create NSData from contents of \(self.dataPathURL.absoluteString)!")
            }
        }
        else {
            NSLog("L8RItemSet load() requested but \(self.dataPathURL.absoluteString) does not exist.")
        }
    }
    
    var allItems:[L8RItem] {
        return Array(self.allItemsSet)
    }
    
    var allItemsSortedByDate:[L8RItem] {
        var items:[L8RItem] = Array(self.allItemsSet)
        items.sortInPlace({ (e1, e2) -> Bool in
            //oldest date first
            return e1.createdDate < e2.createdDate
        })
        return items
    }
    
    func itemsForTag(tag:String) -> [L8RItem] {
        return self.allItems.filter { (item) -> Bool in
                item.tag == tag
            }
    }

    func itemsForDate(date:NSDate) -> [L8RItem] {
        return self.allItems.filter { (item) -> Bool in
            item.createdDate.yyyyMMddKey == date.yyyyMMddKey
        }
    }
    
    var itemsForToday:[L8RItem] {
        return itemsForDate(NSDate())
    }
    
    func createItemWithImage(image:UIImage, metadata:NSDictionary?) {
        let date = NSDate()
        let item = L8RItem(date: date)
        item.text = "Created on \(date.yyyyMMddKey)"
        if let callback = self.itemCreatedCallback {
            
            NSThread.dispatchAsyncOnMainQueue() {
                callback(item: item, image:  image)
            }
        }
        item.setImage(image)
//        item.text = "\(dt.yyyyMMddKey)"
        self.addItem(item)

    }

    func addItem(item:L8RItem) {
        if allItemsSet.contains(item) {
            NSLog("Error, trying to add \(item) but it already exists in L8RItemSet, ignoring.")
            return
        }
        allItemsSet.insert(item)
        save()
    }
    
    func removeItem(item:L8RItem) {
        if !allItemsSet.contains(item) {
            NSLog("Error, trying to remove \(item) but it doesn't exist in L8RItemSet, ignoring.")
            return
        }
        allItemsSet.remove(item)
        save()
    }
    
    static func createTestItemSet() -> L8RItemSet {
        let set:L8RItemSet = L8RItemSet()
        
        var start = NSDate().timeIntervalSince1970
        let secInDay:NSTimeInterval = 86400
        start = start - (secInDay*4)
        
        for _ in 1...14 {
            let dt = NSDate(timeIntervalSince1970: start)
            let item = L8RItem(date: dt)
            item.text = "\(dt.yyyyMMddKey)"
            set.addItem(item)
            
            start = start + secInDay
        }
        return set
    }
}