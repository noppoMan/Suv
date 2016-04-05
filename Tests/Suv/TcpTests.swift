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

// Simple Echo Server
private func launchServer() -> TCPServer {
    let server = TCPServer()
    
    try! server.bind(Address(host: "127.0.0.1", port: 9999))
    
    try! server.listen(128) { result in
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
    static var allTests: [(String, TcpTests -> () throws -> Void)] {
        return [
            ("testTcpConnect", testTcpConnect)
        ]
    }
    
    func testTcpConnect(){
        waitUntil(5, description: "TCPServer Connect") { done in
            let server = launchServer()
            let client = TCP()
            
            client.connect(host: "localhost", port: 9999) { res in
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
        }
    }
}
