//
//  NSThread_Extensions.swift
//  l8r
//
//  Created by Diego Doval on 1/7/16.
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation




public func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}



extension NSThread {
    class func dispatchSyncOnMainQueue(block: dispatch_block_t) {
        /*
        Do not use this
        if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
        since Apple says
        "The result of dispatch_get_main_queue() may or may not equal the result of dispatch_get_current_queue()
        when called on the main thread. Comparing the two is not a valid way to test whether code is executing
        on the main thread. Foundation/AppKit programs should use [NSThread isMainThread]. POSIX programs may
        use pthread_main_np(3)."
        as described here https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/dispatch_get_current_queue.3.html
        */
        
        if NSThread.isMainThread() {
            block()
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
    }
///utility function that dispatches an optional block on current thread if not nil
class func dispatchAsyncInBackground(possibleBlock:dispatch_block_t?) {
    if let block = possibleBlock {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
    }
}

class func dispatchAsyncOnMainQueue(possibleBlock:dispatch_block_t?) {
    if let block = possibleBlock {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}
}