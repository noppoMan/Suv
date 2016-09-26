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
            let uri = URL(string: "udp://127.0.0.1:41234")!

            let client = UDPSocket()
            let server = UDPSocket()
            try! server.bind(uri)

            client.read { getResults in
                let (data, _) = try! getResults()
                XCTAssertEqual(data.utf8String!, "pong")
                Loop.defaultLoop.stop()
                client.close()
                server.close()
                done()
            }

            server.read { getResults in
                let (data, uri) = try! getResults()
                XCTAssertEqual(data.utf8String!, "ping")
                server.write("pong".data, uri: uri)
            }

            client.write("ping".data, uri: uri)
        }
    }
}
