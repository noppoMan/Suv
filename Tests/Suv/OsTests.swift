//
//  OsTests.swift
//  Suv
//
//  Created by Yuki Takei on 4/5/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
@testable import Suv

class OSTests: XCTestCase {
    static var allTests: [(String, OSTests -> () throws -> Void)] {
        return [
                   ("testCpuCount", testCpuCount)
        ]
    }
    
    func testCpuCount() {
        XCTAssertGreaterThan(OS.cpuCount, 0)
    }
}
