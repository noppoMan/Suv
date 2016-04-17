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
    static var allTests: [(String, TimerTests -> () throws -> Void)] {
        return [
            ("testTimerTimeout", testTimerTimeout),
            ("testTimerInterval", testTimerInterval)
        ]
    }

    func testTimerTimeout() {
        waitUntil(5, description: "TimerTimeout") { done in
            let timer = Timer(mode: .Timeout, tick: 1000)
            XCTAssertEqual(timer.state, TimerState.Pause)

            let start = Time().unixtime

            timer.start {
                XCTAssertGreaterThan(Time().unixtime - start, 0)
                timer.end()
                XCTAssertEqual(timer.state, TimerState.End)
                Loop.defaultLoop.stop()
                done()
            }
        }
    }

    func testTimerInterval() {
        waitUntil(5, description: "TimerInterval") { done in
            let timer: Timer = Timer(mode: .Interval, tick: 500)
            XCTAssertEqual(timer.state, TimerState.Pause)

            var intervalCounter = 0

            timer.start {
                XCTAssertEqual(timer.state, TimerState.Running)
                intervalCounter+=1
                if intervalCounter >= 3 {
                    timer.end()
                    XCTAssertEqual(timer.state, TimerState.End)
                    done()
                    Loop.defaultLoop.stop()
                }
            }

            let t2 = Timer(tick: 1000)

            t2.start {
                t2.end()
                timer.stop()
            }

            let t3 = Timer(tick: 2000)
            t3.start {
                t3.end()
                XCTAssertEqual(timer.state, TimerState.Stop)
                timer.resume()
                XCTAssertEqual(timer.state, TimerState.Running)
            }
        }
    }

}
