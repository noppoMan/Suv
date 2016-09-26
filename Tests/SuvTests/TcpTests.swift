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
private func launchServer() throws -> TCPServer {
    let server = TCPServer()
    
    let addr =  URL(string: "tcp://0.0.0.0:9999")!
    try server.bind(addr)
    try server.listen { getQueue in
        do {
            _ = try getQueue()
            let client = TCPSocket()
            try server.accept(client)
            
            client.read { getData in
                do {
                    let data = try getData()
                    client.write(data)
                } catch {
                    client.close()
                    XCTFail("\(error)")
                }
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    return server
}

class TcpTests: XCTestCase {
    static var allTests: [(String, (TcpTests) -> () throws -> Void)] {
        return [
            ("testTcpConnect", testTcpConnect)
        ]
    }
    
    func testTcpConnect(){
        waitUntil(5, description: "TCPServer Connect") { done in
            let server = try! launchServer()
            let client = TCPClient(uri: URL(string: "tcp://0.0.0.0:9999")!)
            
            try! client.open { getClient in
                _ = try! getClient()
                
                client.write("Hi!".data)
                
                client.read { getData in
                    do {
                        let data = try getData()
                        XCTAssertEqual(data.utf8String!, "Hi!")
                        server.close()
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
