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
    static var allTests: [(String, (FsTests) -> () throws -> Void)] {
        return [
            ("testRead", testRead),
            ("testWrite", testWrite),
            ("testAppendWrite", testAppendWrite),
            ("testStaticRead", testStaticRead),
            ("testStaticWrite", testStaticWrite),
        ]
    }

    func prepare() {
        unlink(targetFile)
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

    func testRead(){
        FileManager().createFile(atPath: targetFile, contents: "Hello world".data, attributes: [:])
        waitUntil(description: "readFile") { done in
            File.open(path: targetFile, flags: .read) { result in
                switch result {
                case .success(let file):
                    file.read { [unowned file] result in
                        file.close()
                        switch result {
                        case .success(let data):
                            XCTAssertEqual(data.utf8String, "Hello world")
                            done()
                        case .failure(let error):
                            XCTFail("\(error)")
                        }
                    }
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
        }
    }
    
    func testWrite(){
        waitUntil(description: "readWrite") { done in
            File.open(path: targetFile, flags: .truncateReadWrite) { result in
                switch result {
                case .success(let file):
                    file.write("Hello world".data) { [unowned file] result in
                        file.read { result in
                            file.close()
                            switch result {
                            case .success(let data):
                                XCTAssertEqual(data.utf8String, "Hello world")
                                done()
                            case .failure(let error):
                                XCTFail("\(error)")
                            }
                        }
                    }
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
        }
    }
    
    func testAppendWrite(){
        waitUntil(description: "testAppendWrite") { done in
            File.open(path: targetFile, flags: .appendReadWrite) { result in
                switch result {
                case .success(let file):
                    file.write("Hello".data) { [unowned file] result in
                        file.write(" world".data) { result in
                            file.read { result in
                                file.close()
                                switch result {
                                case .success(let data):
                                    XCTAssertEqual(data.utf8String, "Hello world")
                                    done()
                                case .failure(let error):
                                    XCTFail("\(error)")
                                }
                            }
                        }
                    }
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
        }
    }
    
    func testStaticRead(){
        FileManager().createFile(atPath: targetFile, contents: "Hello world".data, attributes: [:])
        waitUntil(description: "testStaticRead") { done in
            File.read(path: targetFile) { result in
                switch result {
                case .success(let data):
                    XCTAssertEqual(data.utf8String, "Hello world")
                    done()
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
        }
    }
    
    func testStaticWrite(){
        waitUntil(description: "testStaticWrite") { done in
            File.write(path: targetFile, data: "Hello world".data) { result in
                File.read(path: targetFile) { result in
                    switch result {
                    case .success(let data):
                        XCTAssertEqual(data.utf8String, "Hello world")
                        done()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            }
        }
    }
}
