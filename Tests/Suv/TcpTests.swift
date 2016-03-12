//
//  TcpTests.swift
//  Suv
//
//  Created by Yuki Takei on 2/15/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import CLibUv
@testable import Suv

#if os(Linux)
    extension TcpTests: XCTestCaseProvider {
        var allTests: [(String, () throws -> Void)] {
            return [
                       ("testTcpConnect", testTcpConnect)
            ]
        }
    }
#endif

// Simple Echo Server
private func launchServer() -> TCPServer {
    let server = TCPServer()
    
    try! server.bind(Address(host: "127.0.0.1", port: 3000))
    
    try! server.listen(128) { [unowned server] result in
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

class TcpTests: XCTestCase {
    
    func testTcpConnect(){
        waitUntil(5, description: "TCPServer Connect") { done in
            let server = launchServer()
            
            let client = TCP()
            
            client.connect(host: "localhost", port: 3000) { [unowned client] res in
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
