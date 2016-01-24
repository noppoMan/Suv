//
//  Runtime.swift
//  Suv
//
//  Created by Yuki Takei on 1/29/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

// TODO Need to remove Foundation
import Foundation
import CLibUv

public extension Process {
 
    public static var pid: Int32 {
        return getpid()
    }
    
    public static var env: [String: String] {
        return NSProcessInfo.processInfo().environment
    }
    
    public static var cwd: String {
        return NSFileManager.defaultManager().currentDirectoryPath
    }
}