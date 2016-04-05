//
//  Cluster.swift
//  Suv
//
//  Created by Yuki Takei on 4/4/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
@testable import Suv

class ClusterTests: XCTestCase {
    static var allTests: [(String, ClusterTests -> () throws -> Void)] {
        return [
            ("testFork", testFork)
        ]
    }
    
    func testFork() {
        let testAppPath = "\(Process.cwd)/Suv-Test-App/.build/debug/SuvTestApp"
        let worker = try! Cluster.fork(exexPath: testAppPath, silent: false)
        
        worker.on { ev in
            if case .Online = ev {
                worker.send(.Message("1"))
            }
            else if case .Message(let message) = ev {
                XCTAssertEqual(message, "2")
                try! worker.process.kill(SIGKILL)
            } else if case .Exit(let status) = ev {
                XCTAssertEqual(status, 0)
            }
        }
        
        Loop.defaultLoop.run()
    }
}
