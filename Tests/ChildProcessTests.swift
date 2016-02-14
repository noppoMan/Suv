//
//  ChildProcessSpec.swift
//  Suv
//
//  Created by Yuki Takei on 2/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import Suv

class ChildProcessTests: XCTestCase {
    func testSpawn(){
        waitUntil(description: "spawn") { done in
            let ls = try! ChildProcess.spawn("ls", ["-la", "/usr/local"])
            
            ls.onExit {
                XCTAssertEqual(ls.status, 0)
                done()
            }
            
            Loop.defaultLoop.run()
        }
    }
}