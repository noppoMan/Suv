//
//  OS.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv
@_exported import Foundation.NSProcessInfo

public struct CPUTimes {
    let user: UInt64
    let nice: UInt64
    let sys: UInt64
    let idle: UInt64
    let irq: UInt64
}

public struct CPUInfo {
    let cputimes: CPUTimes
    let model: String
    let speed: Int32
}

extension CPUInfo: CustomStringConvertible {
    public var description: String {
        let uptimeStr = "cputimes: [user:\(cputimes.user), nice: \(cputimes.nice), sys: \(cputimes.sys), idle: \(cputimes.idle), irq: \(cputimes.irq)]"
        let partition = [String](repeating: "-", count: uptimeStr.characters.count).joined(separator: "")
        
        var message = ""
        message += partition
        message += "\n"
        message += "\(uptimeStr)"
        message += "\n"
        message += "model: \(model)"
        message += "\n"
        message += "speed: \(speed)"
        message += "\n"
        message += partition
        message += "\n"
        
        return message
    }
}

/**
 For Getting OS information
 */
extension ProcessInfo {
    
    public static func cpus() -> [CPUInfo] {
        var info: UnsafeMutablePointer<uv_cpu_info_t>?
        info = UnsafeMutablePointer<uv_cpu_info_t>.allocate(capacity: MemoryLayout<uv_cpu_info_t>.size)
        
        var cpuCount: Int32 = 0
        uv_cpu_info(&info, &cpuCount)
        
        var cpus = [CPUInfo]()
        
        for i in 0..<Int(cpuCount) {
            let cpuInfo = info![i]
            let cputimes = CPUTimes(
                user: cpuInfo.cpu_times.user,
                nice: cpuInfo.cpu_times.nice,
                sys: cpuInfo.cpu_times.sys,
                idle: cpuInfo.cpu_times.idle,
                irq: cpuInfo.cpu_times.irq
            )
            
            cpus.append(CPUInfo(cputimes: cputimes, model: String(validatingUTF8: cpuInfo.model) ?? "", speed: cpuInfo.speed))
        }
        
        // free
        uv_free_cpu_info(info, cpuCount)
        
        return cpus
    }
    
    public static func residentsetmem() -> Int {
        var size = 0
        uv_resident_set_memory(&size)
        
        return size
    }
    
    public static func totalmem() -> UInt64 {
        return uv_get_total_memory()
    }
    
    public static func freemem() -> UInt64 {
        return uv_get_free_memory()
    }
    
    public static func uptime() -> Double {
        var uptime: Double = 0
        uv_uptime(&uptime)
        
        return uptime
    }
}
