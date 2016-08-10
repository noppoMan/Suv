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

    init(timeout: Int, description: String, callback:  (@escaping () -> ()) -> ()){
        print("Starting the \(description) test")

        var breakFlag = false

        let done = {
            breakFlag = true
        }

        callback(done)

        let endts = Time().addSec(timeout).unixtime

        let t = TimerWrap(mode: .interval, tick: 100)
        t.start {
            if Time().unixtime > endts {
                Loop.defaultLoop.stop()
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
    func waitUntil(_ timeout: Int = 1, description: String, callback: (@escaping () -> ()) -> ()){
        let _ = AsynchronousTestSupporter(timeout: timeout, description: description, callback: callback)
        Loop.defaultLoop.run()
    }
}


internal typealias SeriesCB =  (@escaping (Error?) -> ()) -> ()

internal func seriesTask(_ tasks: [SeriesCB], _ completion: @escaping (Error?) -> Void) {
    if tasks.count == 0 {
        completion(nil)
        return
    }
    
    var index = 0
    
    func _series(_ current: SeriesCB?) {
        if let cur = current {
            cur { err in
                if let e = err {
                    return completion(e)
                }
                index += 1
                let next: SeriesCB? = index < tasks.count ? tasks[index] : nil
                _series(next)
            }
        } else {
            completion(nil)
        }
    }
    
    _series(tasks[index])
}