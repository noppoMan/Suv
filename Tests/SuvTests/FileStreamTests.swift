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
            ("testStreamReandAndWrite", testStreamReandAndWrite)
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
    
    func testStreamReandAndWrite(){
        waitUntil(description: "testStreamReandAndWrite") { done in
            let writeStream = WritableFileStream(path: targetFile)
            let data = "foobar".data
            
            writeStream.write(data) { result in
                writeStream.close()
                switch result {
                case .success(_):
                    let readStream = ReadableFileStream(path: targetFile)
                    readStream.read { result in
                        switch result {
                        case .success(let data):
                            XCTAssertEqual(data.utf8String!, "foobar")
                            readStream.close()
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
    
}
