//
//  FileStreamTests.swift
//  Suv
//
//  Created by Yuki Takei on 6/13/16.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
@testable import Suv

private let targetFile = Process.cwd + "/test.txt"

class FileStreamTests: XCTestCase {
    static var allTests: [(String, (FileStreamTests) -> () throws -> Void)] {
        return [
            ("testReadFile", testFileStream)
        ]
    }
    
    func prepare() {
        unlink(targetFile)
        waitUntil(description: "setup") { done in
            FS.open(targetFile, flags: .w) { getFd in
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
    
    func testFileStream(){
        waitUntil(description: "readFileStream") { done in
            FS.createWritableStream(path: targetFile) { getStream in
                let stream = try! getStream()
                
                let data: Data = "foobar"
                
                stream.send(data) { result in
                    try! stream.close()
                    
                    _ = try! result()
                    
                    FS.createReadableStream(path: targetFile) { getStream in
                        let stream = try! getStream()
                        stream.receive { getData in
                            let data = try! getData()
                            XCTAssertEqual("\(data)", "foobar")
                            try! stream.close()
                            print(data)
                            done()
                        }
                    }
                }
            }
        }
    }
    
}
