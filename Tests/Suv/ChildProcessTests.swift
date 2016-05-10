//
//  ChildProcessSpec.swift
//  Suv
//
//  Created by Yuki Takei on 2/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
@testable import Suv

class ChildProcessTests: XCTestCase {
    static var allTests: [(String, (ChildProcessTests) -> () throws -> Void)] {
        return [
            ("testSpawn", testSpawn)
        ]
    }
    
    func testSpawn(){
        waitUntil(description: "spawn") { done in
            let ls = try! ChildProcess.spawn("ls", ["-la", "/usr/local"])
            
            ls.onExit { status in
                XCTAssertEqual(status, 0)
                done()
            }
        }
    }
}