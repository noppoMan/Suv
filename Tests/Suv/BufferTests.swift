//
//  BufferTests.swift
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

class BufferTests: XCTestCase {
    static var allTests: [(String, BufferTests -> () throws -> Void)] {
        return [
            ("testToString", testToString)
        ]
    }
    
    func testToString() {
        // from bytes to UTF8
        XCTAssertEqual(Buffer([97]).toString(), "a")
        
        // from string to Base64
        XCTAssertEqual(Buffer("Hello Suv").toString(.Base64), "SGVsbG8gU3V2")
        
        // from string to Hex
        XCTAssertEqual(Buffer("Hello Suv").toString(.Hex), "48656c6c6f20537576")
        
        // Decode base64 string as Buffer and it to UTF8 string
        XCTAssertEqual(try! Base64.decode("SGVsbG8gU3V2").toString(), "Hello Suv")
    }
}

