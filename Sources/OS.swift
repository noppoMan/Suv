//
//  CpuInfo.swift
//  Suv
//
//  Created by Yuki Takei on 1/25/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

func getCpuCount() -> Int32 {
    var info = UnsafeMutablePointer<uv_cpu_info_t>.alloc(sizeof(uv_cpu_info_t))
    let cpuCount = UnsafeMutablePointer<Int32>.alloc(sizeof(Int32))
    uv_cpu_info(&info, cpuCount)
    uv_free_cpu_info(info, cpuCount.memory)
    return cpuCount.memory
}

private let _cpuCount = getCpuCount()

public struct OS {
    public static let cpuCount = _cpuCount
}