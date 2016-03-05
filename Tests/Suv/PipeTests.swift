//
//  PipeTests.swift
//  Suv
//
//  Created by Yuki Takei on 2/16/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

//
//  Pipe.swift
//  Suv
//
//  Created by Yuki Takei on 2/16/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
@testable import Suv

#if os(Linux)
    extension PipeTests: XCTestCaseProvider {
        var allTests: [(String, () throws -> Void)] {
            return [
                       ("testPipeConnect", testPipeConnect)
            ]
        }
    }
#endif

// Simple Echo Server
private func launchServer() -> PipeServer {
    let server = PipeServer()
    
    try! server.bind("/tmp/suv-test.sock")
    
    try! server.listen(128) {result in
        if case .Error(let error) = result {
            XCTFail("\(error)")
            return server.close()
        }
        
        let client = TCP()
        try! server.accept(client)
        
        client.read { result in
            if case let .Data(buf) = result {
                client.write(buf)
            } else if case .Error = result {
                client.close()
            } else {
                client.close()
            }
        }
    }
    
    return server
}

class PipeTests: XCTestCase {
    
    func testPipeConnect(){
        waitUntil(5, description: "PipeServer Connect") { done in
            let server = launchServer()
            
            let client = Pipe()
            
            client.connect("/tmp/suv-test.sock") { res in
                client.write(Buffer("Hi!")) { res in
                    client.read { res in
                        if case .Data(let buf) = res {
                            XCTAssertEqual(buf.toString()!, "Hi!")
                        }
                        
                        server.close()
                        Loop.defaultLoop.stop()
                        done()
                    }
                }
            }
            
            Loop.defaultLoop.run()
        }
    }
}


