//
//  Date.swift
//  Suv
//
//  Created by Yuki Takei on 2/8/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

/**
 TimeZone set
 - UTC
 - Local
 */
public enum TimeZone {
    case UTC
    case Local
}

private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
private let monthes = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


/**
 Time handle class without NSDate
 */
public class Time {
    let length = 80
    
    var tmInfo: UnsafeMutablePointer<tm>
    
    /**
     - parameter tz: TimeZone
    */
    public init(tz: TimeZone = .Local){
        var timer: time_t = time(nil)
        
        if case .UTC = tz {
            self.tmInfo = gmtime(&timer)
        } else {
            self.tmInfo = localtime(&timer)
        }
    }
    
    /**
     Returns rfc822 formated date string
     
     https://hackage.haskell.org/package/time-http-0.5/docs/Data-Time-Format-RFC822.html
    */
    public static var rfc822: String {
        return Time(tz: .UTC).rfc822
    }
    
    /**
     Returns rfc1123 formated date string
     
     http://www.freesoft.org/CIE/RFC/1945/14.htm
     */
    public static var rfc1123: String {
        return Time(tz: .UTC).rfc1123
    }
    
    /**
     Returns rfc822 formated date string
     
     https://hackage.haskell.org/package/time-http-0.5/docs/Data-Time-Format-RFC822.html
     */
    public var rfc822: String {
        return format("%a, %d %b %Y %H:%M:%S %z")
    }
    
    /**
     Returns rfc1123 formated date string
     
     http://www.freesoft.org/CIE/RFC/1945/14.htm
     */
    public var rfc1123: String {
        let day = days[week]
        let mon = monthes[month]
        return format("\(day), %d \(mon) %Y %H:%M:%S GMT")
    }
    
    /**
     Returns unixtime
    */
    public var unixtime: Int {
        return Int(mktime(tmInfo))
    }
    
    /**
     Returns "%A, %B %d %Y %X" formated date string
    */
    public var string: String {
        return format("%A, %B %d %Y %X")
    }
    
    /**
     days since Sunday (from 0)
    */
    public var week: Int {
        return Int(tmInfo.memory.tm_wday)
    }
    
    /**
     years since 1900 (from 0)
     */
    public var year: Int {
        return Int(tmInfo.memory.tm_year)
    }
    
    /**
     month of the year (from 0)
    */
    public var month: Int {
        return Int(tmInfo.memory.tm_mon)
    }
    
    /**
     day of the year (from 0)
    */
    public var yday: Int {
        return Int(tmInfo.memory.tm_yday)
    }
    
    /**
     day of the month (from 1)
    */
    public var day: Int {
        return Int(tmInfo.memory.tm_mday)
    }
    
    /**
     hour of the day (from 0)
    */
    public var hour: Int {
        return Int(tmInfo.memory.tm_hour)
    }
    
    /**
     minutes after the hour (from 0)
     */
    public var min: Int {
        return Int(tmInfo.memory.tm_min)
    }
    
    /**
     seconds after the minute (from 0)
     */
    public var sec: Int {
        return Int(tmInfo.memory.tm_sec)
    }
    
    /**
     add x day
     - parameter x: Number that want to add
    */
    public func addDay(x: Int) -> Time {
        self.tmInfo.memory.tm_mday += Int32(x)
        return self
    }
    
    /**
     add x hour
     - parameter x: Number that want to add
     */
    public func addHour(x: Int) -> Time {
        self.tmInfo.memory.tm_hour += Int32(x)
        return self
    }
    
    /**
     add x minute
     - parameter x: Number that want to add
     */
    public func addMin(x: Int) -> Time {
        self.tmInfo.memory.tm_min += Int32(x)
        return self
    }
    
    /**
     add x seconds
     - parameter x: Number that want to add
     */
    public func addSec(x: Int) -> Time {
        self.tmInfo.memory.tm_sec += Int32(x)
        return self
    }
    
    /**
     Returns specific formated date string
     
     The Format is same with strftime in c lang
     
     ```
     SPECIFIER   FIELDS   DESCRIPTION (EXAMPLE)
     %a      tm_wday  abbreviated weekday name (Sun)
     %A      tm_wday  full weekday name (Sunday)
     %b      tm_mon   abbreviated month name (Dec)
     %B      tm_mon   full month name (December)
     %c       [all]   date and time (Sun Dec  2 06:55:15 1979)
     %Ec      [all]   + era-specific date and time
     %C      tm_year  + year/100 (19)
     %EC     tm_mday  + era specific era name
     tm_mon
     tm_year
     %d      tm_mday  day of the month (02)
     %D      tm_mday  + month/day/year from 01/01/00 (12/02/79)
     tm_mon
     tm_year
     %e      tm_mday  + day of the month, leading space for zero ( 2)
     %F      tm_mday  + year-month-day (1979-12-02)
     tm_mon
     tm_year
     %g      tm_wday  + year for ISO 8601 week, from 00 (79)
     tm_yday
     tm_year
     %G      tm_wday  + year for ISO 8601 week, from 0000 (1979)
     tm_yday
     tm_year
     %h      tm_mon   + same as %b (Dec)
     %H      tm_hour  hour of the 24-hour day, from 00 (06)
     %I      tm_hour  hour of the 12-hour day, from 01 (06)
     %j      tm_yday  day of the year, from 001 (336)
     %m      tm_mon   month of the year, from 01 (12)
     %M      tm_min   minutes after the hour (55)
     %n               + newline character \n
     %p      tm_hour  AM/PM indicator (AM)
     %r      tm_sec   + 12-hour time, from 01:00:00 AM (06:55:15 AM)
     tm_min
     tm_hour
     %Er     tm_sec   + era-specific date and 12-hour time
     tm_min
     tm_hour
     tm_mday
     tm_mon
     tm_year
     %R      tm_min   + hour:minute, from 01:00 (06:55)
     tm_hour
     %S      tm_sec   seconds after the minute (15)
     %t               + horizontal tab character \t
     %T      tm_sec   + 24-hour time, from 00:00:00 (06:55:15)
     tm_min
     tm_hour
     %u      tm_wday  + ISO 8601 day of the week, to 7 for Sunday (7)
     %U      tm_wday  Sunday week of the year, from 00 (48)
     tm_yday
     %V      tm_wday  + ISO 8601 week of the year, from 01 (48)
     tm_yday
     tm_year
     %w      tm_wday  day of the week, from 0 for Sunday (0)
     %W      tm_wday  Monday week of the year, from 00 (48)
     tm_yday
     %x       [all]   date (02/12/79)
     %Ex      [all]   + era-specific date
     %X       [all]   time, from 00:00:00 (06:55:15)
     %EX      [all]   + era-specific time
     %y      tm_year  year of the century, from 00 (79)
     %Ey     tm_mday  + year of the era
     tm_mon
     tm_year
     %Y      tm_year  year (1979)
     %EY     tm_mday  + era-specific era name and year of the era
     tm_mon
     tm_year
     %z      tm_isdst + time zone (hours east*100 + minutes), if any (-0500)
     %Z      tm_isdst time zone name, if any (EST)
     %%               percent character %
     ```
     
     - parameter format: Number that want to add
     */
    public func format(format: String) -> String {
        
        var buffer = [Int8](count: length, repeatedValue: 0)
        strftime(&buffer, length, format, self.tmInfo)
        
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