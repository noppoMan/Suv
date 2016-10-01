//
//  UDPTests.swift
//  Suv
//
//  Created by Yuki Takei on 6/16/16.
//
//

import XCTest
@testable import Suv

class UDPTests: XCTestCase {
    static var allTests: [(String, (UDPTests) -> () throws -> Void)] {
        return [
            ("testUdpConnect", testUdpConnect)
        ]
    }

    func testUdpConnect(){
        waitUntil(5, description: "UDP connection") { done in
            let addr = Address(host: "127.0.0.1", port: 41234)

            let client = UDP()
            let server = UDP()
            try! server.bind(addr)

            client.recv { result in
                switch result {
                case .success(let data, _):
                    XCTAssertEqual(data.utf8String!, "pong")
                    Loop.defaultLoop.stop()
                    client.close()
                    server.close()
                    done()
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }

            server.recv { result in
                switch result {
                case .success(let data, let addr):
                    XCTAssertEqual(data.utf8String!, "ping")
                    server.send("pong".data, addr: addr)
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }

            client.send("ping".data, addr: addr)
        }
    }
}
