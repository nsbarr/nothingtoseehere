//
//  Copyright © 2016 poemsio. All rights reserved.
//

import Foundation

extension String {
    
    public static func createUUIDString() -> String? {
        var resultString:String? = nil
        if let uuid = CFUUIDCreate(nil) {
            resultString = CFUUIDCreateString(nil, uuid) as String
        }
        return resultString
    }
    
}

extension NSDate {
    public func daysDifferenceWith(date: NSDate) -> Int {
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let components = calendar.components(NSCalendarUnit.Day, fromDate: self, toDate: date, options: [])
        return components.day
    }
    ///beginning of day is 12:00 of the day in question, as opposed to midnight which is 12:00 of the next day
    public var startOfDay: NSDate {
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let preservedComponents:NSCalendarUnit = [NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day]
        let startOfDay:NSDate! = calendar.dateFromComponents(calendar.components(preservedComponents, fromDate: self))
        
        if startOfDay == nil {
            NSLog("Error - could not compute startOfDay date for \(self). Returning self!")
            return self
        }
        
        return startOfDay
    }
    
    public var yyyyMMddKey:String {
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let components = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: self)
        return String(format: "%04d-%02d-%02d", components.year, components.month, components.day)
    }
    // utility functions for determining date boundaries
    public func isEqualTo(otherDate:NSDate, ignoreTime:Bool) -> Bool {
        if !ignoreTime {
            return self.isEqualToDate(otherDate)
        }
        
        let comparisonComponents:NSCalendarUnit = [.Year, .Month, .Day]
        let components1:NSDateComponents = NSCalendar.autoupdatingCurrentCalendar().components(comparisonComponents, fromDate: self)
        let components2:NSDateComponents = NSCalendar.autoupdatingCurrentCalendar().components(comparisonComponents, fromDate: otherDate)
        
        return ((components1.year == components2.year) &&
            (components1.month == components2.month) &&
            (components1.day == components2.day));
    }
    
    public var isToday:Bool {
        return self.isEqualTo(NSDate(), ignoreTime: true)
    }
    
    public func isBefore(otherDate:NSDate) -> Bool {
        return self < otherDate
    }
    
    public func isAfter(otherDate:NSDate) -> Bool {
        return !self.isBefore(otherDate)
    }
    
}

//date comparison only up to second resolution - ie, ignores sub-second differences
public func<(lhs:NSDate, rhs:NSDate) -> Bool {
    return Int(lhs.timeIntervalSince1970) < Int(rhs.timeIntervalSince1970)
}