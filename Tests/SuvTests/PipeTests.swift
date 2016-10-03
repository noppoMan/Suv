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
private func launchServer() throws -> Suv.Pipe {
    let server = Suv.Pipe()
    try server.bind("/tmp/suv-test.sock")
    
    try server.listen { result in
        switch result {
        case .success(_):
            let client = Suv.Pipe()
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

class PipeTests: XCTestCase {
    static var allTests: [(String, (PipeTests) -> () throws -> Void)] {
        return [
            ("testPipeConnect", testPipeConnect)
        ]
    }
    
    func testPipeConnect(){
        waitUntil(5, description: "PipeServer Connect") { done in
            let server = try! launchServer()
            let client = Suv.Pipe()
            client.connect("/tmp/suv-test.sock") { result in
                switch result {
                case .success(_):
                    client.write("Hi!".data)
                    client.read { result in
                        switch result {
                        case .success(let data):
                            server.close()
                            XCTAssertEqual(data.utf8String!, "Hi!")
                            Loop.defaultLoop.stop()
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


