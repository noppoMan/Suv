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
import Time
@testable import Suv

class TimerTests: XCTestCase {
    static var allTests: [(String, (TimerTests) -> () throws -> Void)] {
        return [
            ("testTimerTimeout", testTimerTimeout),
            ("testTimerInterval", testTimerInterval)
        ]
    }

    func testTimerTimeout() {
        waitUntil(5, description: "TimerTimeout") { done in
            let timer = TimerWrap(mode: .timeout, tick: 1000)
            XCTAssertEqual(timer.state, TimerState.pause)

            let start = Time().unixtime

            timer.start {
                XCTAssertGreaterThan(Time().unixtime - start, 0)
                timer.end()
                XCTAssertEqual(timer.state, TimerState.end)
                Loop.defaultLoop.stop()
                done()
            }
        }
    }

    func testTimerInterval() {
        waitUntil(5, description: "TimerInterval") { done in
            let timer = TimerWrap(mode: .interval, tick: 500)
            XCTAssertEqual(timer.state, TimerState.pause)

            var intervalCounter = 0

            timer.start {
                XCTAssertEqual(timer.state, TimerState.running)
                intervalCounter+=1
                if intervalCounter >= 3 {
                    timer.end()
                    XCTAssertEqual(timer.state, TimerState.end)
                    done()
                    Loop.defaultLoop.stop()
                }
            }

            let t2 = TimerWrap(tick: 1000)

            t2.start {
                t2.end()
                timer.stop()
            }

            let t3 = TimerWrap(tick: 2000)
            t3.start {
                t3.end()
                XCTAssertEqual(timer.state, TimerState.stop)
                timer.resume()
                XCTAssertEqual(timer.state, TimerState.running)
            }
        }
    }

}
