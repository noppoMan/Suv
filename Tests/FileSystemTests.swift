//
//  FsSpec.swift
//  Suv
//
//  Created by Yuki Takei on 2/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
import Suv

private let targetFile = Process.cwd + "/test.txt"

class FileSystemTests: XCTestCase {
    
    override func setUp() {
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
    
    override func tearDown(){
        unlink(targetFile)
    }
    
    func testRead() {
        waitUntil(description: "readFile") { done in
            let fs = FileSystem(path: targetFile)
            fs.open(.R) { _ in
                XCTAssertGreaterThanOrEqual(fs.fd, 0)
                fs.read { result in
                    fs.close()
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
            Loop.defaultLoop.run()
        }
    }
    
    func testWrite() {
        waitUntil(description: "writeFile") { done in
            let fs = FileSystem(path: targetFile)
            fs.open(.W) { _ in
                XCTAssertGreaterThanOrEqual(fs.fd, 0)
                fs.write(Buffer("test text")) { res in
                    if case .Error(let err) = res {
                        return XCTFail("\(err)")
                    }
                    fs.close()
                    done()
                }
            }
            Loop.defaultLoop.run()
        }
    }
    
    func testReadAndWrite() {
        waitUntil(5, description: "ReadAndWrite") { done in
            let fs = FileSystem(path: targetFile)
            fs.open(.RP) { _ in
                XCTAssertGreaterThanOrEqual(fs.fd, 0)
                
                seriesTask([
                    { cb in
                        fs.write(Buffer("test text")) { res in
                            if case .Error(let err) = res {
                                cb(err)
                            }
                            cb(nil)
                        }
                    },
                    { cb in
                        fs.read { res in
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
                    fs.close()
                    if let e = err {
                        return XCTFail("\(e)")
                    }
                    done()
                }
            }
            Loop.defaultLoop.run()
        }
    }
    
    func testTruncateAndWrite() {
        waitUntil(5, description: "RWAndAppend") { done in
            seriesTask([
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.open(.W) { _ in
                        XCTAssertGreaterThanOrEqual(fs.fd, 0)
                        fs.write(Buffer("foofoofoo")) { res in
                            fs.close()
                            if case .Error(let err) = res {
                                cb(err)
                            }
                            cb(nil)
                        }
                    }
                },
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.open(.WP) { _ in
                        XCTAssertGreaterThanOrEqual(fs.fd, 0)
                        fs.write(Buffer("bar")) { res in
                            fs.close()
                            if case .Error(let err) = res {
                                cb(err)
                            }
                            cb(nil)
                        }
                    }
                },
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.open(.R) { _ in
                        fs.read { res in
                            switch(res) {
                            case .Error(let e):
                                cb(e)
                            case .Data(let buf):
                                XCTAssertEqual(buf.toString()!, "bar")
                            case .End(let pos):
                                XCTAssertEqual(fs.pos, pos)
                                cb(nil)
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
            Loop.defaultLoop.run()
        }
    }

    
    func testAppend() {
        waitUntil(5, description: "RWAndAppend") { done in
            seriesTask([
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.open(.W) { _ in
                        XCTAssertGreaterThanOrEqual(fs.fd, 0)
                        fs.write(Buffer("foo")) { res in
                            fs.close()
                            if case .Error(let err) = res {
                                cb(err)
                            }
                            cb(nil)
                        }
                    }
                },
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.open(.A) { _ in
                        XCTAssertGreaterThanOrEqual(fs.fd, 0)
                        fs.write(Buffer("bar"), position: 3) { res in
                            fs.close()
                            if case .Error(let err) = res {
                                cb(err)
                            }
                            cb(nil)
                        }
                    }
                },
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.open(.AP) { _ in
                        XCTAssertGreaterThanOrEqual(fs.fd, 0)
                        fs.write(Buffer("baz"), position: 6) { res in
                            fs.close()
                            if case .Error(let err) = res {
                                cb(err)
                            }
                            cb(nil)
                        }
                        
                    }
                },
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.open(.R) { _ in
                        fs.read { res in
                            switch(res) {
                            case .Error(let e):
                                cb(e)
                            case .Data(let buf):
                                XCTAssertEqual(buf.toString()!, "foobarbaz")
                            case .End(let pos):
                                XCTAssertEqual(fs.pos, pos)
                                cb(nil)
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
            Loop.defaultLoop.run()
        }
    }
    
    func testStat(){
        waitUntil(5, description: "stat") { done in
            seriesTask([
                { cb in
                    let fs = FileSystem(path: "invalid file path")
                    fs.stat { res in
                        if case .Error(let err) = res {
                            XCTAssertNotNil(err)
                            return cb(nil)
                        }
                        cb(SuvError.RuntimeError(message: "Here has never been called"))
                    }
                },
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.stat { res in
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
            Loop.defaultLoop.run()
        }
    }
    
    func testFtell(){
        waitUntil(5, description: "fell") { done in
            let fs = FileSystem(path: targetFile)
            fs.open(.WP) { _ in
                XCTAssertGreaterThanOrEqual(fs.fd, 0)
                
                let str = "hello world.hello world.hello world.hello world.hello world."
                
                fs.write(Buffer(str)) { res in
                    
                    if case .Error(let err) = res {
                        fs.close()
                        return XCTFail("\(err)")
                    }
                    
                    fs.rewind()
                    XCTAssertEqual(fs.pos, 0)
                    
                    fs.ftell { pos in
                        fs.close()
                        XCTAssertEqual(pos, str.characters.count)
                        done()
                    }
                }
            }
            Loop.defaultLoop.run()
        }
    }
    
    func testErrorFd() {
        waitUntil(5, description: "ErrorFd") { done in
            seriesTask([
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.open(.R) { _ in
                        XCTAssertGreaterThanOrEqual(fs.fd, 0)
                        fs.write(Buffer("foo")) { res in
                            fs.close()
                            if case .Error(let err) = res {
                                XCTAssertNotNil(err)
                                return cb(nil)
                            }
                            cb(SuvError.RuntimeError(message: "Here has never been called"))
                        }
                    }
                },
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.open(.W) { _ in
                        fs.read { res in
                            if case .Error(let err) = res {
                                XCTAssertNotNil(err)
                                return cb(nil)
                            }
                            cb(SuvError.RuntimeError(message: "Here has never been called"))
                        }
                    }
                },
                { cb in
                    let fs = FileSystem(path: targetFile)
                    fs.open(.A) { _ in
                        fs.read { res in
                            if case .Error(let err) = res {
                                XCTAssertNotNil(err)
                                return cb(nil)
                            }
                            cb(SuvError.RuntimeError(message: "Here has never been called"))
                        }
                    }
                }
            ]) { err in
                if let e = err {
                    return XCTFail("\(e)")
                }
                done()
            }
            Loop.defaultLoop.run()
        }
    }
}