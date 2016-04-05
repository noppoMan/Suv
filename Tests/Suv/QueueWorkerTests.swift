//
//  QueueWorkerTests.swift
//  Suv
//
//  Created by Yuki Takei on 3/4/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import CLibUv
@testable import Suv

class QueueWorkerTests: XCTestCase {
    static var allTests: [(String, QueueWorkerTests -> () throws -> Void)] {
        return [
            ("testQWork", testQWork)
        ]
    }
    
    func testQWork() {
        var cnt = 0
        
        Process.qwork(onThread: {
            cnt+=1
        })
        
        Process.qwork(onThread: { cnt+=1 }, onFinish: {
            XCTAssertEqual(cnt, 2)
            Loop.defaultLoop.stop()
        })
        
        Loop.defaultLoop.run()
    }
}
