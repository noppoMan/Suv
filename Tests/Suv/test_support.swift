//
//  support.swift
//  Suv
//
//  Created by Yuki Takei on 2/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import Foundation
import Time
@testable import Suv

private class AsynchronousTestSupporter {

    init(timeout: Int, description: String, callback: (() -> ()) -> ()){
        print("Starting the \(description) test")

        var breakFlag = false

        let done = {
            breakFlag = true
        }

        callback(done)

        let endts = Time().addSec(timeout).unixtime

        let t = Timer(mode: .Interval, tick: 100)
        t.start {
            if Time().unixtime > endts {
                XCTFail("Test is timed out")
            }

            if(breakFlag) {
                t.end()
            }
        }
        t.unref()
    }
}


extension XCTestCase {
    func waitUntil(timeout: Int = 1, description: String, callback: (() -> ()) -> ()){
        let _ = AsynchronousTestSupporter(timeout: timeout, description: description, callback: callback)
        Loop.defaultLoop.run()
    }
}
