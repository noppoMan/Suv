//
//  support.swift
//  Suv
//
//  Created by Yuki Takei on 2/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import Foundation

private class AsynchronousTestSupporter {

    init(timeout: NSTimeInterval, description: String, callback: (() -> ()) -> ()){
        print("Starting the \(description) test")

        var breakFlag = false

        let done = {
            breakFlag = true
        }

        callback(done)

        let runLoop = NSRunLoop.currentRunLoop()
        let timeoutDate = NSDate(timeIntervalSinceNow: timeout)

        while NSDate().compare(timeoutDate) == NSComparisonResult.OrderedAscending {
            if(breakFlag) {
                break
            }
            runLoop.runUntilDate(NSDate(timeIntervalSinceNow: 0.01))
        }

        if(!breakFlag) {
            XCTFail("Test is timed out")
        }
    }
}


extension XCTestCase {
    func waitUntil(timeout: NSTimeInterval = 1, description: String, callback: (() -> ()) -> ()){
        let _ = AsynchronousTestSupporter(timeout: timeout, description: description, callback: callback)

        // Should restore if the https://github.com/apple/swift-corelibs-xctest/pull/43 is merged
//        let expectation = expectationWithDescription("readFile")
//
//        let done = {
//            expectation.fulfill()
//        }
//
//        callback(done)
//
//        waitForExpectationsWithTimeout(timeout) { error in
//            if let error = error {
//                print("Error: \(error.localizedDescription)")
//            }
//        }
    }
}
