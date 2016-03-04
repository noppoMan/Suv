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

#if os(Linux)
    extension QueueWorkerTests: XCTestCaseProvider {
        var allTests: [(String, () throws -> Void)] {
            return [
                       ("testQWork", testQWork)
            ]
        }
    }
#endif

class QueueWorkerTests: XCTestCase {
    
    func testQWork() {
        waitUntil(description: "Process.qwork") { done in
            var cnt = 0
            
            Process.qwork(onThread: {
                cnt+=1
            })
            
            Process.qwork(onThread: {
                cnt+=2
                XCTAssertEqual(cnt, 3)
            })
            
            Process.qwork(onThread: { cnt+=3 }, onFinish: {
                XCTAssertEqual(cnt, 6)
                done()
                Loop.defaultLoop.stop()
            })
            
            Loop.defaultLoop.run()
        }
    }
}
