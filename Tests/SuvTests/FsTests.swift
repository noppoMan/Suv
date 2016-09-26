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

private let targetFile = CommandLine.cwd + "/test.txt"

class FsTests: XCTestCase {
    static var allTests: [(String, (FsTests) -> () throws -> Void)] {
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
            FS.open(targetFile, flags: .truncateWrite) { getFd in
                let fd = try! getFd()
                FS.close(fd)
                done()
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
            FS.readFile(targetFile) { getData in
                do {
                    let data = try getData()
                    XCTAssertEqual(data.count, 0)
                    done()
                } catch {
                    XCTFail("\(error)")
                }
            }
        }
    }

    func testRead() {
        waitUntil(description: "readFile") { done in
            FS.open(targetFile, flags: .read) { getFd in
                let fd = try! getFd()
                XCTAssertGreaterThanOrEqual(fd, 0)
                FS.read(fd) { getData in
                    FS.close(fd)
                    let data = try! getData()
                    XCTAssertEqual(data.count, 0)
                    done()
                }
            }
        }
    }

    func testWriteFile(){
        waitUntil(description: "writeFile") { done in
            FS.writeFile(targetFile, withString: "Hello world") { _ in
                FS.readFile(targetFile) { getData in
                    let data = try! getData()    
                    XCTAssertEqual(data.utf8String!, "Hello world")
                    done()
                }
            }
        }
    }

    func testWrite() {
        waitUntil(description: "writeFile") { done in
            FS.open(targetFile, flags: .truncateWrite) { getFd in
                let fd = try! getFd()
                XCTAssertGreaterThanOrEqual(fd, 0)
                FS.write(fd, data: "test text".data) { result in
                    _ = try! result()
                    FS.close(fd)
                    done()
                }
            }
        }
    }

    func testReadAndWrite() {
        waitUntil(5, description: "ReadAndWrite") { done in
            FS.open(targetFile, flags: .readWrite) { getFd in
                let fd = try! getFd()
                XCTAssertGreaterThanOrEqual(fd, 0)
                seriesTask([
                   { cb in
                        FS.write(fd, data: "test text".data) { result in
                            do {
                                _ = try result()
                                cb(nil)
                            } catch {
                                cb(error)
                            }
                        }
                    },
                    { cb in
                        FS.read(fd) { getData in
                            do {
                                let data = try getData()
                                XCTAssertEqual(data.utf8String!, "test text")
                                cb(nil)
                            } catch {
                                cb(error)
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

    func testTruncateAndWrite() {
        waitUntil(5, description: "RWAndAppend") { done in
            seriesTask([
                { cb in
                    FS.open(targetFile, flags: .truncateWrite) { getFd in
                        let fd = try! getFd()
                        XCTAssertGreaterThanOrEqual(fd, 0)
                        FS.write(fd, data: "foofoofoo".data) { result in
                            FS.close(fd)
                            do {
                                _  = try result()
                                cb(nil)
                            } catch {
                                cb(error)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .truncateReadWrite) { getFd in
                        let fd = try! getFd()
                        XCTAssertGreaterThanOrEqual(fd, 0)
                        FS.write(fd, data: "bar".data) { result in
                            FS.close(fd)
                            do {
                                _  = try result()
                                cb(nil)
                            } catch {
                                cb(error)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .read) { getFd in
                        let fd = try! getFd()
                        XCTAssertGreaterThanOrEqual(fd, 0)
                        FS.read(fd) { getData in
                            do {
                                let data = try getData()
                                XCTAssertEqual(data.utf8String!, "bar")
                                cb(nil)
                            } catch {
                                cb(error)
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
                    FS.readFile(targetFile) { getData in
                        let data = try! getData()
                        XCTAssertEqual(data.utf8String!, "foobar")
                        done()
                    }
                }
            }
        }
    }

    func testAppend() {
        waitUntil(5, description: "RWAndAppend") { done in
            seriesTask([
                { cb in
                    FS.open(targetFile, flags: .truncateWrite) { getfd in
                        let fd = try! getfd()
                        XCTAssertGreaterThanOrEqual(fd, 0)
                        FS.write(fd, data: "foo".data) { result in
                            FS.close(fd)
                            do {
                                _ = try result()
                                cb(nil)
                            } catch {
                                cb(error)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .appendWrite) { getfd in
                        let fd = try! getfd()
                        XCTAssertGreaterThanOrEqual(fd, 0)
                        FS.write(fd, data: "bar".data, position: 3) { result in
                            FS.close(fd)
                            do {
                                _ = try result()
                                cb(nil)
                            } catch {
                                cb(error)
                            }
                        }
                    }
                },
                { cb in
                    
                    FS.open(targetFile, flags: .appendReadWrite) { getfd in
                        let fd = try! getfd()
                        XCTAssertGreaterThanOrEqual(fd, 0)
                        FS.write(fd, data: "baz".data, position: 6) { result in
                            FS.close(fd)
                            do {
                                _ = try result()
                                cb(nil)
                            } catch {
                                cb(error)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .read) { getfd in
                        let fd = try! getfd()
                        XCTAssertGreaterThanOrEqual(fd, 0)
                        FS.read(fd) { getData in
                            do {
                                let data = try getData()
                                XCTAssertEqual(data.utf8String!, "foobarbaz")
                            } catch {
                                cb(error)
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
            FS.open(targetFile, flags: .truncateReadWrite) { getfd in
                let fd = try! getfd()
                XCTAssertGreaterThanOrEqual(fd, 0)
                let str = "hello world.hello world.hello world.hello world.hello world."
                
                FS.write(fd, data: Data(str)) { result in
                    do {
                        _ = try result()
                        FS.ftell(fd) { getPos in
                            FS.close(fd)
                            XCTAssertEqual(try! getPos(), str.characters.count)
                            done()
                        }
                        
                    } catch {
                        FS.close(fd)
                        XCTFail("\(error)")
                    }
                }
            }
        }
    }

    func testStat(){
        waitUntil(5, description: "stat") { done in
            seriesTask([
                { cb in
                    FS.stat("invalid file path") { result in
                        do {
                            _ = try result()
                            XCTFail("Here has never been called")
                        } catch {
                            cb(nil)
                        }
                    }
                },
                { cb in
                    FS.stat(targetFile) { result in
                        do {
                            _ = try result()
                            cb(nil)
                        } catch {
                            cb(error)
                        }
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
            FS.exists(targetFile) { result in
                XCTAssertTrue(try! result())
                FS.exists("invalid file path") { result in
                    XCTAssertFalse(try! result())
                    done()
                }
            }
        }
    }

    func testErrorFd() {
        waitUntil(5, description: "ErrorFd") { done in
            seriesTask([
                { cb in
                    FS.open(targetFile, flags: .read) { getfd in
                        let fd = try! getfd()
                        XCTAssertGreaterThanOrEqual(fd, 0)
                        FS.write(fd, data: "foo".data) { result in
                            FS.close(fd)
                            do {
                                try result()
                                XCTFail("Here has been never called")
                            } catch {
                                XCTAssertNotNil(error)
                                cb(nil)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .truncateWrite) { getfd in
                        let fd = try! getfd()
                        XCTAssertGreaterThanOrEqual(fd, 0)
                        FS.read(fd) { getData in
                            FS.close(fd)
                            do {
                                _ = try getData()
                                XCTFail("Here has been never called")
                            } catch {
                                XCTAssertNotNil(error)
                                cb(nil)
                            }
                        }
                    }
                },
                { cb in
                    FS.open(targetFile, flags: .appendWrite) { getfd in
                        let fd = try! getfd()
                        XCTAssertGreaterThanOrEqual(fd, 0)
                        FS.read(fd) { getData in
                            FS.close(fd)
                            do {
                                _ = try getData()
                                XCTFail("Here has been never called")
                            } catch {
                                XCTAssertNotNil(error)
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
        }
    }
}
