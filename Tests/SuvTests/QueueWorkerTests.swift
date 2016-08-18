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

func fibonacci(_ number: Int) -> (Int) {
    if number <= 1 {
        return number
    } else {
        return fibonacci(number - 1) + fibonacci(number - 2)
    }
}

class QueueWorkerTests: XCTestCase {
    static var allTests: [(String, (QueueWorkerTests) -> () throws -> Void)] {
        return [
            ("testQWork", testQWork)
        ]
    }
    
    func testQWork() {
        Process.qwork(onThread: { ctx in
            ctx.storage["result"] = fibonacci(10)
        }, onFinish: { ctx in
            XCTAssertEqual(55, ctx.storage["result"] as! Int)
            Loop.defaultLoop.stop()
        })
        
        Loop.defaultLoop.run()
    }
}
