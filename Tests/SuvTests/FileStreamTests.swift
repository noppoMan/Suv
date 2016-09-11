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

private let targetFile = CommandLine.cwd + "/test.txt"

class FileStreamTests: XCTestCase {
    static var allTests: [(String, (FileStreamTests) -> () throws -> Void)] {
        return [
            ("testReadFile", testFileStream)
        ]
    }
    
    func prepare() {
        unlink(targetFile)
        waitUntil(description: "setup") { done in
            FS.open(targetFile, flags: .createWrite) { getFd in
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
            let writeStream = FS.createWritableStream(path: targetFile)
            let data: C7.Data = "foobar"
            
            writeStream.send(data) { result in
                try! writeStream.close()
                
                _ = try! result()
                
                let readStream = FS.createReadableStream(path: targetFile)
                readStream.receive { getData in
                    let data = try! getData()
                    XCTAssertEqual("\(data)", "foobar")
                    try! readStream.close()
                    done()
                }
            }
        }
    }
    
}
