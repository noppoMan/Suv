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
private func launchServer() throws -> TCP {
    let server = TCP()
    let addr =  Address(host: "0.0.0.0", port: 9999)
    try server.bind(addr)
    try server.listen { result in
        switch result {
        case .success(_):
            let client = TCP()
            try! server.accept(client)
            client.read { result in
                switch result {
                case .success(let data):
                    client.write(data)
                case .failure(let error):
                    client.close()
                    XCTFail("\(error)")
                }
            }
        case .failure(let error):
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
            let client = TCP()
            
            client.connect(Address(host: "0.0.0.0", port: 9999)) { result in
                switch result {
                case .success(_):
                    client.write("Hi!".data)
                    client.read { result in
                        switch result {
                        case .success(let data):
                            XCTAssertEqual(data.utf8String!, "Hi!")
                            server.close()
                            Loop.defaultLoop.stop()
                            done()
                        case .failure(let error):
                            client.close()
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
