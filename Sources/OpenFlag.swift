//
//  OpenFlag.swift
//  Suv
//
//  Created by Yuki Takei on 2/14/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

/**
 Open Flag for FileSystem.open
 
 - R: fopen's r
 - W: fopen's w
 - A: fopen's a
 - RP: fopen's r+
 - WP: fopen's w+
 - AP: fopen's a+
 */
public enum OpenFlag: Int32 {
    case R   // r
    case W   // w
    case A   // a
    case RP  // r+
    case WP  // w+
    case AP  // a+
}


// Refere from node.js's fs.js #stringToFlags
extension OpenFlag {
    /**
     Returns raw value of OR Operated Flags
    */
    public var rawValue: Int32 {
        switch(self) {
        case .R:
            return O_RDONLY
        case .RP:
            return O_RDWR
        case .W:
            return O_TRUNC | O_CREAT | O_WRONLY
        case .WP:
            return O_TRUNC | O_CREAT | O_RDWR
        case .A:
            return O_APPEND | O_CREAT | O_WRONLY
        case .AP:
            return O_APPEND | O_CREAT | O_RDWR
        }
    }
    
    /**
     Default mode that related with flags
    */
    public var mode: Int32 {
        switch(self) {
        case .R:
            return 0
        case .RP:
            return 0
        case .W:
            return 0o666
        case .WP:
            return 0o666
        case .A:
            return 0o666
        case .AP:
            return 0o666
        }
    }
}
