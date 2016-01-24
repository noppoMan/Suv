//
//  Date.swift
//  Suv
//
//  Created by Yuki Takei on 2/8/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

// "%a, %d %b %Y %H:%M:%S %z"

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum TimeZone {
    case UTC
    case Local
}

private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
private let monthes = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

public class Time {
    let length = 80
    
    var tmInfo: UnsafeMutablePointer<tm>
    
    public init(tz: TimeZone = .Local){
        var timer: time_t = time(nil)
        
        if case .UTC = tz {
            self.tmInfo = gmtime(&timer)
        } else {
            self.tmInfo = localtime(&timer)
        }
    }
    
    public static var rfc822: String {
        return Time(tz: .UTC).rfc822
    }
    
    public static var rfc1123: String {
        return Time(tz: .UTC).rfc1123
    }
    
    public var rfc822: String {
        return format("%a, %d %b %Y %H:%M:%S %z")
    }
    
    public var rfc1123: String {
        let day = days[week]
        let mon = monthes[month]
        return format("\(day), %d \(mon) %Y %H:%M:%S GMT")
    }
    
    public var string: String {
        return format("%A, %B %d %Y %X")
    }
    
    public var week: Int {
        return Int(tmInfo.memory.tm_wday)
    }
    
    public var year: Int {
        return Int(tmInfo.memory.tm_year)
    }
    
    public var month: Int {
        return Int(tmInfo.memory.tm_mon)
    }
    
    public var yday: Int {
        return Int(tmInfo.memory.tm_yday)
    }
    
    public var day: Int {
        return Int(tmInfo.memory.tm_mday)
    }
    
    public var hour: Int {
        return Int(tmInfo.memory.tm_hour)
    }
    
    public var min: Int {
        return Int(tmInfo.memory.tm_min)
    }
    
    public var sec: Int {
        return Int(tmInfo.memory.tm_sec)
    }
    
    public func addDay(x: Int) -> Time {
        self.tmInfo.memory.tm_mday += Int32(x)
        return self
    }
    
    public func addHour(x: Int) -> Time {
        self.tmInfo.memory.tm_hour += Int32(x)
        return self
    }
    
    public func addMin(x: Int) -> Time {
        self.tmInfo.memory.tm_min += Int32(x)
        return self
    }
    
    public func addSec(x: Int) -> Time {
        self.tmInfo.memory.tm_sec += Int32(x)
        return self
    }
    
    public func format(format: String) -> String {
        let buffer = UnsafeMutablePointer<Int8>.alloc(length)
        defer {
            buffer.destroy()
            buffer.dealloc(length)
        }
        
        strftime(buffer, length, format, self.tmInfo)
        
        var buf = Buffer()
        for i in 0..<length {
            if(buffer[i] == 0) {
                break
            }
            buf.append(buffer[i])
        }
        
        guard let dateStr = buf.toString() else {
            return ""
        }
        
        return dateStr
    }
}