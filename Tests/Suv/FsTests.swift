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

private let targetFile = Process.cwd + "/test.txt"

class FsTests: XCTestCase {
    static var allTests: [(String, FsTests -> () throws -> Void)] {
        return [
            ("testReadFile", testReadFile),
            ("testWriteFile", testWriteFile),
            ("testAppendFile", testAppendFile),
            ("testExists", testExists),
            ("testRead", testRead),
            ("testWrite", testWrite),
            ("testReadAndWrite", testReadAndWrite),
            ("testTruncateAndWrite", testTruncateAndWrite),
            ("testAppend", testAppend),
            ("testStat", testStat),
            ("testStat", testFtell),
            ("testErrorFd", testErrorFd)
        ]
    }

    func prepare() {
        unlink(targetFile)

        waitUntil(description: "setup") { done in
            FS.open(targetFile, flags: .W) { res in
                if case .Success(let fd) = res {
                    FS.read(fd) { result in
                        FS.close(fd)
                        done()
                    }
                }
            }
        }
    }

    func cleanup(){
        unlink(targetFile)
    }

    override func setUp() {
        prepare()
    }

    override func tearDown(){
        cleanup()
    }
    
    func testReadFile(){
        waitUntil(description: "readFile") { done in
            FS.readFile(targetFile) { res in
                if case .Success(let buf) = res {
                    XCTAssertEqual(buf.bytes.count, 0)
                }
                done()
            }
        }
    }

    func testRead() {
        waitUntil(description: "readFile") { done in
            FS.open(targetFile, flags: .R) { result in
                if case .Success(let fd) = result {
                    XCTAssertGreaterThanOrEqual(fd, 0)
                    FS.read(fd) { result in
                        FS.close(fd)
                        if case .Error(let err) = result {
                            XCTFail("\(err)")
                        } else if case .Data = result {
                            // noop
                        } else if case .End(let pos) = result {
                            XCTAssertEqual(pos, 0)
                            done()
                        }
                    }
                }
            }
        }
    }
    
    func testWriteFile(){
        waitUntil(description: "writeFile") { done in
            FS.writeFile(targetFile, withString: "Hello world") { res in
                FS.readFile(targetFile) { res in
                    if case .Success(let buf) = res {
                        XCTAssertEqual(buf.toString()!, "Hello world")
                        done()
                    } else if case .Error(let e) = res {
                        XCTFail("\(e)")
                    }
                }
            }
        }
    }
    
    func testWrite() {
        waitUntil(description: "writeFile") { done in
            FS.open(targetFile, flags: .W) { result in
                if case .Success(let fd) = result {
                    XCTAssertGreaterThanOrEqual(fd, 0)
                    FS.write(fd, withBuffer: Buffer(string: "test text")) { result in
                        if case .Error(let err) = result {
                            return XCTFail("\(err)")
                        }
                        
                        FS.close(fd)
                        done()
                    }
                }
            }
        }
    }
    
    func testReadAndWrite() {
        waitUntil(5, description: "ReadAndWrite") { done in
            FS.open(targetFile, flags: .RP) { res in
                if case .Success(let fd) = res {
                    XCTAssertGreaterThanOrEqual(fd, 0)
                    seriesTask([
                       { cb in
                            FS.write(fd, withBuffer: Buffer(string: "test text")) { res in
                                if case .Error(let err) = res {
                                    return cb(err)
                                }
                                cb(nil)
                            }
                        },
                        { cb in
                            FS.read(fd) { res in
                                switch(res) {
                                case .Error(let e):
                                    cb(e)
                                case .Data(let buf):
                                    XCTAssertEqual(buf.toString()!, "test text")
                                case .End(let pos):
                                    XCTAssertEqual(pos, 9)
                                    cb(nil)
                                }
                            }
                        },
                    ]) { err in
                        FS.close(fd)
                        if let e = err {
                            return XCTFail("\(e)")
                        }
                        done()
                    }
                }
            }
        }
    }

    func testTruncateAndWrite() {
        waitUntil(5, description: "RWAndAppend") { done in
            seriesTask([
                { cb in
                    FS.open(targetFile, flags: .W) { res in
                        if case .Success(let fd) = res {
                            XCTAssertGreaterThanOrEqual(fd, 0)
                            FS.write(fd, withBuffer: Buffer(string: "foofoofoo")) { res in
                                FS.close(fd)
                                if case .Error(let err) = res {
                                    cb(err)
                                }
                                cb(nil)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .WP) { res in
                        if case .Success(let fd) = res {
                            XCTAssertGreaterThanOrEqual(fd, 0)
                            FS.write(fd, withBuffer: Buffer(string: "bar")) { res in
                                FS.close(fd)
                                if case .Error(let err) = res {
                                    cb(err)
                                }
                                cb(nil)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .R) { res in
                        if case .Success(let fd) = res {
                            FS.read(fd) { res in
                                switch(res) {
                                case .Error(let e):
                                    cb(e)
                                case .Data(let buf):
                                    XCTAssertEqual(buf.toString()!, "bar")
                                case .End(let pos):
                                    XCTAssertEqual(3, pos)
                                    cb(nil)
                                }
                            }
                        }
                    }
                }
            ]) { err in
                if let e = err {
                    return XCTFail("\(e)")
                }
                done()
            }
        }
    }
    
    func testAppendFile(){
        waitUntil(description: "appendFile") { done in
            FS.writeFile(targetFile, withString: "foo") { _ in
                FS.appendFile(targetFile, withString: "bar") { _ in
                    FS.readFile(targetFile) { res in
                        if case .Success(let buf) = res {
                            XCTAssertEqual(buf.toString()!, "foobar")
                            done()
                        } else if case .Error(let e) = res {
                            XCTFail("\(e)")
                        }
                    }
                }
            }
        }
    }
    
    func testAppend() {
        waitUntil(5, description: "RWAndAppend") { done in
            seriesTask([
                { cb in
                    FS.open(targetFile, flags: .W) { res in
                        if case .Success(let fd) = res {
                            XCTAssertGreaterThanOrEqual(fd, 0)
                            FS.write(fd, withBuffer: Buffer(string: "foo")) { res in
                                FS.close(fd)
                                if case .Error(let err) = res {
                                    cb(err)
                                }
                                cb(nil)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .A) { res in
                        if case .Success(let fd) = res {
                            XCTAssertGreaterThanOrEqual(fd, 0)
                            FS.write(fd, withBuffer: Buffer(string: "bar"), position: 3) { res in
                                FS.close(fd)
                                if case .Error(let err) = res {
                                    cb(err)
                                }
                                cb(nil)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .AP) { res in
                        if case .Success(let fd) = res {
                            XCTAssertGreaterThanOrEqual(fd, 0)
                            FS.write(fd, withBuffer: Buffer(string: "baz"), position: 6) { res in
                                FS.close(fd)
                                if case .Error(let err) = res {
                                    cb(err)
                                }
                                cb(nil)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .R) { res in
                        if case .Success(let fd) = res {
                            FS.read(fd) { res in
                                switch(res) {
                                case .Error(let e):
                                    cb(e)
                                case .Data(let buf):
                                    XCTAssertEqual(buf.toString()!, "foobarbaz")
                                case .End(let pos):
                                    XCTAssertEqual(9, pos)
                                    cb(nil)
                                }
                            }
                        }
                    }
                }
            ]) { err in
                if let e = err {
                    return XCTFail("\(e)")
                }
                done()
            }
        }
    }
    
    func testFtell(){
        waitUntil(5, description: "fell") { done in
            FS.open(targetFile, flags: .WP) { res in
                if case .Success(let fd) = res {
                    XCTAssertGreaterThanOrEqual(fd, 0)
                    let str = "hello world.hello world.hello world.hello world.hello world."
                    
                    FS.write(fd, withBuffer: Buffer(string: str)) { res in
                        if case .Error(let err) = res {
                            FS.close(fd)
                            return XCTFail("\(err)")
                        } else if case .Success(let pos) = res {
                            XCTAssertEqual(pos, str.characters.count)
                        }
                        
                        FS.ftell(fd) { pos in
                            FS.close(fd)
                            XCTAssertEqual(pos, str.characters.count)
                            done()
                        }
                    }
                }
            }
        }
    }
    
    func testStat(){
        waitUntil(5, description: "stat") { done in
            seriesTask([
                { cb in
                    FS.stat("invalid file path") { res in
                        if case .Error(let err) = res {
                            XCTAssertNotNil(err)
                            return cb(nil)
                        }
                        cb(SuvError.RuntimeError(message: "Here has never been called"))
                    }
                },
                { cb in
                    FS.stat(targetFile) { res in
                        if case .Error(let err) = res {
                            return cb(err)
                        }
                        cb(nil)
                    }
                },
            ]) { err in
                if let e = err {
                    return XCTFail("\(e)")
                }
                done()
            }
        }
    }

    func testExists(){
        waitUntil(description: "exists") { done in
            FS.exists(targetFile) { yes in
                XCTAssertTrue(yes)
                FS.exists("invalid file path") { yes in
                    XCTAssertFalse(yes)
                    done()
                }
            }
        }
    }
    
    func testErrorFd() {
        waitUntil(5, description: "ErrorFd") { done in
            seriesTask([
                { cb in
                    FS.open(targetFile, flags: .R) { res in
                        if case .Success(let fd) = res {
                            XCTAssertGreaterThanOrEqual(fd, 0)
                            FS.write(fd, withBuffer: Buffer(string: "foo")) { res in
                                FS.close(fd)
                                if case .Error(let err) = res {
                                    XCTAssertNotNil(err)
                                    return cb(nil)
                                }
                                cb(SuvError.RuntimeError(message: "Here has never been called"))
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .W) { res in
                        if case .Success(let fd) = res {
                            FS.read(fd) { res in
                                if case .Error(let err) = res {
                                    XCTAssertNotNil(err)
                                    return cb(nil)
                                }
                                cb(SuvError.RuntimeError(message: "Here has never been called"))
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .A) { res in
                        if case .Success(let fd) = res {
                            FS.read(fd) { res in
                                if case .Error(let err) = res {
                                    XCTAssertNotNil(err)
                                    return cb(nil)
                                }
                                cb(SuvError.RuntimeError(message: "Here has never been called"))
                            }
                        }
                    }
                }
            ]) { err in
                if let e = err {
                    return XCTFail("\(e)")
                }
                done()
            }
        }
    }
}
