//
//  TimerTests.swift
//  Suv
//
//  Created by Yuki Takei on 2/19/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
import Foundation
@testable import Suv

class TimerTests: XCTestCase {
    static var allTests: [(String, (TimerTests) -> () throws -> Void)] {
        return [
            ("testTimer", testTimer)
        ]
    }

    func testTimer() {
        waitUntil(10, description: "TimerTimeout") { done in
            let timerTimeout: SeriesCB = { cb in
                let timer = TimerWrap(mode: .timeout, delay: 1000)
                timer.unref()
                XCTAssertEqual(timer.state, TimerState.pause)
                
                let start = Int(Date().timeIntervalSince1970)
                
                timer.start {
                    XCTAssertGreaterThan(Int(Date().timeIntervalSince1970) - start, 0)
                    timer.end()
                    XCTAssertEqual(timer.state, TimerState.end)
                    Loop.defaultLoop.stop()
                    cb(nil)
                }
            }
            
            
            let timerInterval: SeriesCB = { cb in
                let timer = TimerWrap(mode: .interval, delay: 500)
                timer.unref()
                XCTAssertEqual(timer.state, TimerState.pause)
                
                var intervalCounter = 0
                
                timer.start {
                    XCTAssertEqual(timer.state, TimerState.running)
                    intervalCounter+=1
                    if intervalCounter >= 3 {
                        timer.end()
                        XCTAssertEqual(timer.state, TimerState.end)
                        cb(nil)
                        Loop.defaultLoop.stop()
                    }
                }
                
                let t2 = TimerWrap(delay: 1000)
                
                t2.start {
                    t2.end()
                    timer.stop()
                }
                
                let t3 = TimerWrap(delay: 2000)
                t3.start {
                    t3.end()
                    XCTAssertEqual(timer.state, TimerState.stop)
                    timer.resume()
                    XCTAssertEqual(timer.state, TimerState.running)
                }
            }
            
            seriesTask([timerTimeout, timerInterval]) { _ in
                done()
            }
        }
    }
}
