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
    
    /**
     Returns current pid
     */
    public static var pid: Int32 {
        return getpid()
    }
    
    /**
     Returns environment variables
     */
    public static var env: [String: String] {
        return NSProcessInfo.processInfo().environment
    }
    
    /**
     Returns current working directory
     */
    public static var cwd: String {
        return NSFileManager.defaultManager().currentDirectoryPath
    }
}