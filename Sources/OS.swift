//
//  CpuInfo.swift
//  Suv
//
//  Created by Yuki Takei on 1/25/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

func getCpuCount() -> Int32 {
    var info: UnsafeMutablePointer<uv_cpu_info_t>?
    info = UnsafeMutablePointer<uv_cpu_info_t>(allocatingCapacity: sizeof(uv_cpu_info_t))
    
    var cpuCount: Int32 = 0
    uv_cpu_info(&info, &cpuCount)
    uv_free_cpu_info(info, cpuCount)
    return cpuCount
}

/**
 For Getting OS information
 */
public struct OS {
    
    /**
     Returns number of cpu count
     */
    public static let cpuCount = getCpuCount()
}