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

// Simple Echo Server
private func launchServer() throws -> PipeServer {
    let server = PipeServer()    
    try server.bind("/tmp/suv-test.sock")
    
    try server.listen { result in
        do {
            _ = try result()
            let client = PipeSocket()
            try server.accept(client)
            
            client.receive { getData in
                do {
                    let data = try getData()
                    client.send(data)
                } catch {
                    try! client.close()
                    XCTFail("\(error)")
                }
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    return server
}

class PipeTests: XCTestCase {
    static var allTests: [(String, (PipeTests) -> () throws -> Void)] {
        return [
            ("testPipeConnect", testPipeConnect)
        ]
    }
    
    func testPipeConnect(){
        waitUntil(5, description: "PipeServer Connect") { done in
            let server = try! launchServer()
            
            let client = PipeClient(sockName: "/tmp/suv-test.sock")
            
            try! client.open { result in
                _ = try! result()
                
                client.send(Data("Hi!"))
                
                client.receive { getData in
                    do {
                        let data = try getData()
                        try! server.close()
                        XCTAssertEqual("\(data)", "Hi!")
                        Loop.defaultLoop.stop()
                        done()
                    } catch {
                        XCTFail("\(error)")
                    }
                }
            }
        }
    }
}


