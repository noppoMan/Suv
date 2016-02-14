//
//  FsTests.swift
//  Suv
//
//  Created by Yuki Takei on 2/14/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import Suv

private let targetFile = Process.cwd + "/test.txt"

class FsTests: XCTestCase {
    
    override func setUp() {
        waitUntil(description: "setup") { done in
            Fs.unlink(targetFile)
            Fs.createFile(targetFile) { _ in
                done()
            }
            Loop.defaultLoop.run()
        }
    }
    
    override func tearDown(){
        let fs = FileSystem(path: targetFile)
        fs.unlink()
        Loop.defaultLoop.run()
    }
    
    func testReadFile(){
        waitUntil(description: "readFile") { done in
            Fs.readFile(targetFile) { res in
                if case .End(let pos) = res {
                    XCTAssertEqual(pos, 0)
                }
                done()
            }
            Loop.defaultLoop.run()
        }
    }
    
}
