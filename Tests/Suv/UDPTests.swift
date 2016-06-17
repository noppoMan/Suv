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
            let uri = URI(host: "127.0.0.1", port: 41234)

            let client = UDPSocket()
            let server = UDPSocket()
            try! server.bind(uri)

            client.receive { getResults in
                let (data, _) = try! getResults()
                XCTAssertEqual("\(data)", "pong")
                Loop.defaultLoop.stop()
                try! client.close()
                try! server.close()
                done()
            }

            server.receive { getResults in
                let (data, uri) = try! getResults()
                XCTAssertEqual("\(data)", "ping")
                server.send(Data("pong"), uri: uri)
            }

            client.send(Data("ping"), uri: uri)
        }
    }
}
