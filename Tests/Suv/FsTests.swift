//
//  FsTests.swift
//  Suv
//
//  Created by Yuki Takei on 2/14/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
@testable import Suv

#if os(Linux)
    extension FsTests: XCTestCaseProvider {
        var allTests: [(String, () throws -> Void)] {
            return [
                ("testReadFile", testReadFile),
                ("testWriteFile", testWriteFile),
                ("testAppendFile", testAppendFile),
                ("testExists", testExists),
            ]
        }
    }
#endif

private let targetFile = Process.cwd + "/test.txt"

class FsTests: XCTestCase {

    func prepare() {
        unlink(targetFile)

        waitUntil(description: "setup") { done in
            let fs = FileSystem(path: targetFile)
            fs.open(.W) { res in
                XCTAssertGreaterThanOrEqual(fs.fd, 0)
                fs.close()
                if case .Error(let err) = res {
                    return XCTFail("\(err)")
                }
                done()
            }
            Loop.defaultLoop.run()
        }
    }

    func cleanup(){
        unlink(targetFile)
    }

    #if os(OSX)
    override func setUp() {
        prepare()
    }

    override func tearDown(){
        cleanup()
    }
    #else
    func setUp() {
        prepare()
    }

    func tearDown(){
        cleanup()
    }
    #endif

    func testReadFile(){
        waitUntil(description: "readFile") { done in
            Fs.readFile(targetFile) { res in
                if case .Success(let buf) = res {
                    XCTAssertEqual(buf.bytes.count, 0)
                }
                done()
            }
            Loop.defaultLoop.run()
        }
    }

    func testWriteFile(){
        waitUntil(description: "writeFile") { done in

            Fs.writeFile(targetFile, data: "Hello world") { res in
                Fs.readFile(targetFile) { res in
                    if case .Success(let buf) = res {
                        XCTAssertEqual(buf.toString()!, "Hello world")
                        done()
                    } else if case .Error(let e) = res {
                        XCTFail("\(e)")
                    }
                }
            }

            Loop.defaultLoop.run()
        }
    }

    func testAppendFile(){
        waitUntil(description: "appendFile") { done in
            Fs.writeFile(targetFile, data: "foo") { _ in
                Fs.appendFile(targetFile, data: "bar") { _ in
                    Fs.readFile(targetFile) { res in
                        if case .Success(let buf) = res {
                            XCTAssertEqual(buf.toString()!, "foobar")
                            done()
                        } else if case .Error(let e) = res {
                            XCTFail("\(e)")
                        }
                    }
                }
            }

            Loop.defaultLoop.run()
        }
    }

    func testExists(){
        waitUntil(description: "exists") { done in

            Fs.exists(targetFile) { yes in
                XCTAssertTrue(yes)
                Fs.exists("invalid file path") { yes in
                    XCTAssertFalse(yes)
                    done()
                }
            }

            Loop.defaultLoop.run()
        }
    }

}
