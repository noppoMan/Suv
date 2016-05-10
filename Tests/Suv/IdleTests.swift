//
//  IdleTests.swift
//  Suv
//
//  Created by Yuki Takei on 3/4/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
@testable import Suv

class IdleTests: XCTestCase {
    static var allTests: [(String, (IdleTests) -> () throws -> Void)] {
        return [
            ("testSetImmediate", testSetImmediate)
        ]
    }
    
    func testSetImmediate() {
        waitUntil(description: "Process.setImmediate") { done in
            var cnt = 0
            Process.setImmediate {
                idle.stop()
                cnt += 1
                XCTAssertEqual(cnt, 2)
                done()
            }
            
            cnt += 1
            XCTAssertEqual(cnt, 1)
        }
    }
}

